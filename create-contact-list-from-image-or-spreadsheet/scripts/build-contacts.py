#!/usr/bin/env python3
"""
build-contacts.py — turn a transcribed roster into a CSV + vCards + a numbers list.

Input is a delimited file WITH a header row (TSV or CSV; delimiter auto-detected).
Column names are matched case-insensitively against these aliases:

    first   : first, first name, given, given name
    last    : last, last name, family, family name, surname
    name    : name, full name, fullname          (split into first/last if no first/last cols)
    mobile  : mobile, mobile #, phone, phone #, cell, number

Every other column is carried into the vCard NOTE and the master CSV verbatim.
Rows with a blank mobile are kept in the master CSV and reported, but skipped in
the vCards and numbers.txt (a contact with no number is not a contact).

Usage:
    build-contacts.py --input roster.tsv --out ~/Downloads/LV236-BananaLove \
        --group "LV236-BananaLove" \
        --org   "ChoiceCenter LV236 - BananaLove" \
        --event "ChoiceCenter Discovery, Las Vegas LV236, Aug 27-30 2026" \
        --prefix "LV236 " --region 1
"""
import argparse, csv, io, pathlib, re, sys

ALIASES = {
    "first":  {"first", "first name", "given", "given name"},
    "last":   {"last", "last name", "family", "family name", "surname"},
    "name":   {"name", "full name", "fullname"},
    "mobile": {"mobile", "mobile #", "phone", "phone #", "cell", "number", "mobile number"},
}


def resolve_columns(header):
    """Map canonical field -> actual header string. Returns (mapping, extras)."""
    mapping, claimed = {}, set()
    for canon, names in ALIASES.items():
        for h in header:
            if h.strip().lower() in names and h not in claimed:
                mapping[canon] = h
                claimed.add(h)
                break
    extras = [h for h in header if h not in claimed and h.strip()]
    return mapping, extras


def e164(raw, region="1"):
    """US-default E.164. Returns '' for blank/unusable input."""
    s = (raw or "").strip()
    if not s:
        return ""
    if s.startswith("+"):
        d = re.sub(r"\D", "", s)
        return "+" + d if d else ""
    d = re.sub(r"\D", "", s)
    if not d:
        return ""
    if len(d) == 10:
        return "+" + region + d
    if len(d) == 11 and d.startswith(region):
        return "+" + d
    return "+" + d  # already country-coded, or non-US — pass through, flagged below


def esc(s):
    """vCard 3.0 text escaping (RFC 2426 §5)."""
    return (str(s).replace("\\", "\\\\").replace(";", r"\;")
                  .replace(",", r"\,").replace("\n", r"\n"))


def slugify(s):
    return re.sub(r"[^A-Za-z0-9]+", "-", s).strip("-") or "contact"


def read_rows(path):
    text = pathlib.Path(path).read_text()
    delim = "\t" if text.splitlines()[0].count("\t") >= text.splitlines()[0].count(",") else ","
    r = csv.DictReader(io.StringIO(text), delimiter=delim)
    return [dict(row) for row in r], (r.fieldnames or [])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--group", required=True, help="Short tag, e.g. LV236-BananaLove")
    ap.add_argument("--org", default="", help="ORG field / company on the card")
    ap.add_argument("--event", default="", help="Prose context folded into NOTE")
    ap.add_argument("--prefix", default="", help='Name prefix, e.g. "LV236 " — see SKILL.md')
    ap.add_argument("--region", default="1", help="Default country code, digits only")
    a = ap.parse_args()

    out = pathlib.Path(a.out).expanduser()
    out.mkdir(parents=True, exist_ok=True)
    org = a.org or a.group

    raw, header = read_rows(a.input)
    if not header:
        sys.exit("input has no header row")
    cols, extras = resolve_columns(header)
    if "mobile" not in cols:
        sys.exit(f"no mobile/phone column found in header: {header}")

    people = []
    for row in raw:
        if "first" in cols or "last" in cols:
            first = (row.get(cols.get("first", ""), "") or "").strip()
            last = (row.get(cols.get("last", ""), "") or "").strip()
        elif "name" in cols:
            parts = (row.get(cols["name"], "") or "").strip().split()
            first, last = (parts[0] if parts else ""), (" ".join(parts[1:]) if len(parts) > 1 else "")
        else:
            sys.exit(f"no name column found in header: {header}")
        if not (first or last):
            continue
        people.append({
            "first": first, "last": last,
            "mobile": (row.get(cols["mobile"], "") or "").strip(),
            "extras": {k: (row.get(k, "") or "").strip() for k in extras},
        })

    for i, p in enumerate(people, 1):
        p["n"] = i
        p["e164"] = e164(p["mobile"], a.region)

    withphone = [p for p in people if p["e164"]]
    nophone = [f'{p["first"]} {p["last"]}'.strip() for p in people if not p["e164"]]
    odd = [f'{p["first"]} {p["last"]} -> {p["e164"]}' for p in withphone
           if not re.fullmatch(rf"\+{a.region}\d{{10}}", p["e164"])]

    def note(p):
        bits = [b for b in [a.event, f'Roster #{p["n"]}'] if b]
        bits += [f"{k}: {v}" for k, v in p["extras"].items() if v]
        return ". ".join(bits) + "." if bits else ""

    # ---- master CSV --------------------------------------------------------
    with open(out / f"{a.group}-roster.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["#", "First Name", "Last Name", "Full Name",
                    "Mobile (as given)", "Mobile E.164", *extras, "Group", "Event"])
        for p in people:
            w.writerow([p["n"], p["first"], p["last"], f'{p["first"]} {p["last"]}'.strip(),
                        p["mobile"], p["e164"], *[p["extras"][k] for k in extras],
                        a.group, a.event])

    # ---- Google Contacts CSV (Android / desktop bulk path) -----------------
    gf = ["Name", "Given Name", "Family Name", "Group Membership",
          "Organization 1 - Name", "Organization 1 - Title",
          "Phone 1 - Type", "Phone 1 - Value", "Notes"]
    with open(out / "google-contacts-import.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=gf)
        w.writeheader()
        for p in withphone:
            w.writerow({
                "Name": f'{a.prefix}{p["first"]} {p["last"]}'.strip(),
                "Given Name": f'{a.prefix}{p["first"]}'.strip(),
                "Family Name": p["last"],
                "Group Membership": f"{a.group} ::: * myContacts",
                "Organization 1 - Name": org,
                "Organization 1 - Title": f'Roster #{p["n"]}',
                "Phone 1 - Type": "Mobile",
                "Phone 1 - Value": p["e164"],
                "Notes": note(p),
            })

    # ---- vCard 3.0, prefixed and clean -------------------------------------
    def vcard(p, prefixed):
        first = (a.prefix + p["first"]) if prefixed else p["first"]
        fn = f'{first} {p["last"]}'.strip()
        L = ["BEGIN:VCARD", "VERSION:3.0",
             f'N:{esc(p["last"])};{esc(first)};;;',
             f"FN:{esc(fn)}",
             f"ORG:{esc(org)}",
             f"CATEGORIES:{esc(a.group)}",
             f'TEL;TYPE=CELL,VOICE:{p["e164"]}']
        if note(p):
            L.append(f"NOTE:{esc(note(p))}")
        L.append("END:VCARD")
        return "\r\n".join(L) + "\r\n"

    for prefixed, folder, combined in [
        (bool(a.prefix), "vcards", f"{a.group}-ALL.vcf"),
        (False, "vcards-cleannames", f"{a.group}-ALL-cleannames.vcf"),
    ]:
        d = out / folder
        d.mkdir(exist_ok=True)
        for old in d.glob("*.vcf"):
            old.unlink()
        parts = []
        for p in withphone:
            card = vcard(p, prefixed)
            parts.append(card)
            stem = "%02d-%s" % (p["n"], slugify(p["first"] + " " + p["last"]))
            (d / (stem + ".vcf")).write_text(card, newline="")
        (out / combined).write_text("".join(parts), newline="")

    # ---- numbers.txt -------------------------------------------------------
    # Two shapes on purpose. numbers.txt is the single-line paste for a To:
    # field. numbers-checklist.txt is the same list one-per-line, because users
    # work through a long list in sittings and delete each number as it lands —
    # the file IS the progress bar. Never regenerate either over a copy the
    # user has already started consuming. See SKILL.md.
    nums = [p["e164"] for p in withphone]
    for fname, body in [("numbers.txt", ",".join(nums)),
                        ("numbers-checklist.txt", "\n".join(nums))]:
        f = out / fname
        if f.exists() and f.read_text().strip() != body.strip():
            print(f"  SKIPPED {fname} — already exists and differs; "
                  f"it may be half-consumed. Delete it to regenerate.")
            continue
        f.write_text(body + "\n")

    print(f"rows={len(people)}  with_phone={len(withphone)}  -> {out}")
    if nophone:
        print(f"  NO PHONE (excluded from vCards/numbers.txt): {', '.join(nophone)}")
    if odd:
        print(f"  NON-STANDARD LENGTH (verify by hand): {'; '.join(odd)}")
    dupes = {}
    for p in withphone:
        dupes.setdefault(p["e164"], []).append(f'{p["first"]} {p["last"]}')
    for num, who in dupes.items():
        if len(who) > 1:
            print(f"  DUPLICATE {num}: {', '.join(who)}")


if __name__ == "__main__":
    main()
