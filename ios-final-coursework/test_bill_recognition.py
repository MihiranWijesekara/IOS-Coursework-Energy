#!/usr/bin/env python3
"""
Test suite validating the ElectricityBillParser, character disambiguation,
and ElectricityBillValidator against Sri Lankan bill formats (CEB e-Bill, CEB Printed, LECO).
"""

import re
from decimal import Decimal

class BillFormatType:
    CEB_E_BILL = "CEB e-Bill"
    CEB_PRINTED = "CEB Printed Bill"
    LECO_BILL = "LECO Bill"
    STANDARD = "Standard Bill"
    UNKNOWN = "Unclassified Bill"

def normalize_numeric_token(raw: str) -> tuple[str, bool]:
    result = []
    changed = False
    for ch in raw:
        if ch in ("O", "o"):
            result.append("0")
            changed = True
        elif ch in ("I", "l", "|"):
            result.append("1")
            changed = True
        elif ch in ("S", "s"):
            result.append("5")
            changed = True
        elif ch == "B":
            result.append("8")
            changed = True
        else:
            result.append(ch)
    return "".join(result), changed

def normalize_date_token(raw: str) -> tuple[str, bool]:
    cleaned, changed = normalize_numeric_token(raw)
    return cleaned.replace("/", "-"), changed

def extract_decimal_currency(line: str) -> tuple[Decimal, bool] | None:
    target_slice = line.split(":", 1)[1] if ":" in line else line
    pattern = r"(?:Rs\.?|LKR|\$|£)?\s*([0-9OIlSB]{1,3}(?:,[0-9OIlSB]{3})+|[0-9OIlSB]+)\.[0-9OIlSB]{2}"
    match = re.search(pattern, target_slice)
    if not match:
        return None
    token = match.group(0)
    for prefix in ["Rs.", "rs.", "Rs", "rs", "LKR", "lkr", "$", "£", ","]:
        token = token.replace(prefix, "")
    token = token.strip()
    normalized, was_cleaned = normalize_numeric_token(token)
    try:
        return Decimal(normalized), was_cleaned
    except Exception:
        return None

def is_likely_customer_name(line: str) -> bool:
    trimmed = line.strip()
    if len(trimmed) < 3:
        return False
    forbidden = ["a/c", "account", "b/f", "payment", "outstanding", "reading",
                 "charge", "ssc", "monthly", "total", "view", "http", "ebill", "ceylon"]
    lower = trimmed.lower()
    if any(lower.startswith(f) or "rs." in lower for f in forbidden):
        return False
    has_letters = bool(re.search(r"[A-Za-z]{2,}", trimmed))
    has_digits = bool(re.search(r"\d", trimmed))
    return has_letters and not has_digits

def filter_messaging_chrome(lines: list[str]) -> list[str]:
    filtered = []
    for line in lines:
        lower = line.strip().lower()
        if lower in ("forwarded", "↪ forwarded"):
            continue
        if lower == "open this link to view your electricity bill.":
            continue
        if re.match(r"^\d{1,2}:\d{2}\s*(?:am|pm)?$", lower):
            continue
        filtered.append(line.strip())
    return filtered

def detect_format(lines: list[str]) -> str:
    joined = "\n".join(lines).lower()
    ceb_signals = ["ceb e-bill", "ebill.edl.lk", "a/c no", "b/f", "ssc levy", "sscl levy", "monthly bill", "view e-bill"]
    count = sum(1 for s in ceb_signals if s in joined)
    if count >= 3:
        return BillFormatType.CEB_E_BILL
    if "lanka electricity company" in joined or "leco" in joined:
        return BillFormatType.LECO_BILL
    if "ceylon electricity board" in joined or "ceb" in joined:
        return BillFormatType.CEB_PRINTED
    if any(k in joined for k in ["kwh", "electricity", "meter", "account"]):
        return BillFormatType.STANDARD
    return BillFormatType.UNKNOWN

def parse_ceb_e_bill(lines: list[str]) -> dict:
    data = {
        "formatType": BillFormatType.CEB_E_BILL,
        "provider": "Ceylon Electricity Board (CEB)",
        "accountNumber": None,
        "tariffCode": None,
        "customerName": None,
        "broughtForward": None,
        "payments": None,
        "outstandingBalance": None,
        "outstandingDueDate": None,
        "readingDate": None,
        "readingDateSuffix": None,
        "currentReading": None,
        "previousReading": None,
        "consumptionUnits": None,
        "energyCharge": None,
        "levyAmount": None,
        "monthlyBill": None,
        "totalDue": None,
        "billURL": None,
    }

    for idx, line in enumerate(lines):
        line_clean = line.strip()

        # 1. A/C No
        if re.search(r"(?:A\s*/?\s*C\s*No|Account\s*(?:No|Number))", line_clean, re.I):
            m_ac = re.search(r"(?:A\s*/?\s*C\s*No|Account\s*(?:No|Number))\s*[:\-]?\s*([0-9OIlSB]{8,14})", line_clean, re.I)
            if m_ac:
                data["accountNumber"], _ = normalize_numeric_token(m_ac.group(1))
            m_tf = re.search(r"\(([A-Za-z0-9\s\-]{1,8})\)", line_clean)
            if m_tf:
                data["tariffCode"] = m_tf.group(1).strip()
            if idx + 1 < len(lines):
                candidate = lines[idx + 1].strip()
                if is_likely_customer_name(candidate):
                    data["customerName"] = candidate
            continue

        # 2. B/F
        if re.search(r"^(?:B\s*/\s*F|Brought\s*Forward)\b", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res:
                data["broughtForward"] = res[0]
            continue

        # 3. Payments
        if re.search(r"^Payments?\b", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res:
                data["payments"] = res[0]
            continue

        # 4. Outstanding
        if re.search(r"^Outstanding\b", line_clean, re.I):
            segment = re.sub(r"\bby\s+[0-9OIlSB]{4}[\-/][0-9OIlSB]{2}[\-/][0-9OIlSB]{2}.*$", "", line_clean, flags=re.I)
            res = extract_decimal_currency(segment)
            if res:
                data["outstandingBalance"] = res[0]
            m_dt = re.search(r"\bby\s+([0-9OIlSB]{4}[\-/][0-9OIlSB]{2}[\-/][0-9OIlSB]{2})", line_clean, re.I)
            if m_dt:
                clean_date, _ = normalize_date_token(m_dt.group(1))
                data["outstandingDueDate"] = clean_date
            continue

        # 5. Reading Date
        if re.search(r"^Reading\s*Date\b", line_clean, re.I):
            m_rd = re.search(r"([0-9OIlSB]{4}[\-/][0-9OIlSB]{2}[\-/][0-9OIlSB]{2})", line_clean)
            if m_rd:
                clean_date, _ = normalize_date_token(m_rd.group(1))
                data["readingDate"] = clean_date
            m_suf = re.search(r"\(([A-Za-z0-9]+)\)", line_clean)
            if m_suf:
                data["readingDateSuffix"] = m_suf.group(1)
            continue

        # 6. Reading equation
        if re.search(r"^Reading\s*[:\-]", line_clean, re.I):
            pat = r"Reading\s*[:\-]?\s*([0-9OIlSB]+)\s*[\-–—]\s*([0-9OIlSB]+)\s*=\s*([0-9OIlSB]+)\s*(?:Units?|kWh)?"
            m_eq = re.search(pat, line_clean, re.I)
            if m_eq:
                r1_str, _ = normalize_numeric_token(m_eq.group(1))
                r2_str, _ = normalize_numeric_token(m_eq.group(2))
                u_str, _ = normalize_numeric_token(m_eq.group(3))
                data["currentReading"] = int(r1_str)
                data["previousReading"] = int(r2_str)
                data["consumptionUnits"] = int(u_str)
            continue

        # 7. Charge
        if re.search(r"^(?:Electricity\s+|Energy\s+)?Charge\b", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res:
                data["energyCharge"] = res[0]
            continue

        # 8. SSC Levy
        if re.search(r"^(?:SSC|SSCL)\s*Levy\b", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res:
                data["levyAmount"] = res[0]
            continue

        # 9. Monthly Bill
        if re.search(r"^Monthly\s*Bill\b", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res:
                data["monthlyBill"] = res[0]
            continue

        # 10. Total Due
        if re.search(r"^Total\s*Due\b", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res:
                data["totalDue"] = res[0]
            continue

        # 11. URL
        if line_clean.lower().startswith("http://") or line_clean.lower().startswith("https://"):
            data["billURL"] = line_clean.split()[0]

    return data

def parse_printed_or_standard_bill(lines: list[str]) -> dict:
    data = {
        "formatType": BillFormatType.STANDARD,
        "provider": None,
        "accountNumber": None,
        "tariffCode": None,
        "customerName": None,
        "readingDate": None,
        "dueDate": None,
        "currentReading": None,
        "previousReading": None,
        "consumptionUnits": None,
        "broughtForward": None,
        "payments": None,
        "outstandingBalance": None,
        "energyCharge": None,
        "levyAmount": None,
        "monthlyBill": None,
        "totalDue": None,
    }

    for idx, line in enumerate(lines):
        line_clean = line.strip()

        # Provider
        if not data["provider"]:
            if "ceylon electricity board" in line_clean.lower() or "ceb" in line_clean.lower():
                data["provider"] = "Ceylon Electricity Board (CEB)"
            elif "lanka electricity company" in line_clean.lower() or "leco" in line_clean.lower():
                data["provider"] = "Lanka Electricity Company (LECO)"

        # Account Number
        if not data["accountNumber"]:
            m_ac = re.search(r"(?:Account\s*(?:No|Number|#)?|A\s*/?\s*C\s*No)\s*[:\-]?\s*([A-Z0-9\-]{6,16})", line_clean, re.I)
            if m_ac:
                data["accountNumber"] = m_ac.group(1)

        # Tariff Category
        if not data["tariffCode"]:
            m_tf = re.search(r"Tariff\s*(?:Category|Code)?\s*[:\-]?\s*([A-Z0-9\-]{1,6})", line_clean, re.I)
            if m_tf:
                data["tariffCode"] = m_tf.group(1)

        # Customer Name
        if not data["customerName"]:
            m_nm = re.search(r"(?:Customer\s*Name|Consumer\s*Name|Name)\s*[:\-]?\s*([A-Za-z\s\.]{3,40})", line_clean, re.I)
            if m_nm and not any(kw in m_nm.group(1).lower() for kw in ["account", "tariff", "bill"]):
                data["customerName"] = m_nm.group(1).strip()

        # Reading Equation
        m_eq = re.search(r"([0-9OIlSB]+)\s*[\-–—]\s*([0-9OIlSB]+)\s*=\s*([0-9OIlSB]+)", line_clean)
        if m_eq and ("reading" in line_clean.lower() or "units" in line_clean.lower()):
            r1, _ = normalize_numeric_token(m_eq.group(1))
            r2, _ = normalize_numeric_token(m_eq.group(2))
            u, _ = normalize_numeric_token(m_eq.group(3))
            data["currentReading"] = int(r1)
            data["previousReading"] = int(r2)
            data["consumptionUnits"] = int(u)

        # Explicit readings
        if data["previousReading"] is None:
            m_prev = re.search(r"Previous\s*(?:Meter\s*)?Reading\s*[:\-]?\s*([0-9OIlSB]{3,8})", line_clean, re.I)
            if m_prev:
                p_str, _ = normalize_numeric_token(m_prev.group(1))
                data["previousReading"] = int(p_str)

        if data["currentReading"] is None:
            m_curr = re.search(r"(?:Current|Present)\s*(?:Meter\s*)?Reading\s*[:\-]?\s*([0-9OIlSB]{3,8})", line_clean, re.I)
            if m_curr:
                c_str, _ = normalize_numeric_token(m_curr.group(1))
                data["currentReading"] = int(c_str)

        if data["consumptionUnits"] is None:
            m_cons = re.search(r"(?:Total\s*(?:kWh|Units)|Consumption|Units\s*Consumed|Units\s*Used)\s*[:\-]?\s*([0-9OIlSB]{1,6})", line_clean, re.I)
            if m_cons:
                u_str, _ = normalize_numeric_token(m_cons.group(1))
                data["consumptionUnits"] = int(u_str)

        # Charges & Totals
        if data["energyCharge"] is None and re.search(r"(?:Energy\s*Charge|Electricity\s*Charge|Usage\s*Charge|^Charge\b)", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res: data["energyCharge"] = res[0]

        if data["levyAmount"] is None and re.search(r"(?:SSC\s*Levy|SSCL\s*Levy|Tax\s*&\s*Levy|Levy)", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res: data["levyAmount"] = res[0]

        if data["monthlyBill"] is None and re.search(r"(?:Monthly\s*Bill|Current\s*Month\s*Charges|Total\s*Current\s*Bill)", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res: data["monthlyBill"] = res[0]

        if data["totalDue"] is None and re.search(r"(?:Total\s*Due|Total\s*Amount\s*Due|Amount\s*Payable|Total\s*Payable|Total\s*Amount)", line_clean, re.I):
            res = extract_decimal_currency(line_clean)
            if res: data["totalDue"] = res[0]

        # Dates
        if not data["readingDate"]:
            m_dt = re.search(r"(?:Reading\s*Date|Bill\s*Date|Billing\s*Date)\s*[:\-]?\s*([0-9]{4}[\-/][0-9]{2}[\-/][0-9]{2}|[0-9]{2}[\-/][0-9]{2}[\-/][0-9]{4})", line_clean, re.I)
            if m_dt: data["readingDate"] = m_dt.group(1).replace("/", "-")

        if not data["dueDate"]:
            m_due = re.search(r"(?:Due\s*Date|Payment\s*Due)\s*[:\-]?\s*([0-9]{4}[\-/][0-9]{2}[\-/][0-9]{2}|[0-9]{2}[\-/][0-9]{2}[\-/][0-9]{4})", line_clean, re.I)
            if m_due: data["dueDate"] = m_due.group(1).replace("/", "-")

    return data

def validate_bill(bill: dict) -> list[str]:
    warnings = []
    # 1. Required fields
    if not bill.get("accountNumber"):
        warnings.append("Missing Account Number")
    if not bill.get("readingDate"):
        warnings.append("Missing Reading Date")
    if bill.get("consumptionUnits") is None:
        warnings.append("Missing Consumption (kWh)")
    if bill.get("totalDue") is None and bill.get("monthlyBill") is None:
        warnings.append("Missing Bill Amount")

    # 2. Reading reconciliation
    curr = bill.get("currentReading")
    prev = bill.get("previousReading")
    units = bill.get("consumptionUnits")
    if curr is not None and prev is not None:
        if curr < prev:
            warnings.append("Inconsistent Meter Readings: Current < Previous")
        else:
            diff = curr - prev
            if units is not None and units != diff:
                warnings.append(f"Meter Reading Discrepancy: {curr} - {prev} = {diff} != {units}")

    # 3. Balance reconciliation: B/F - Payments == Outstanding
    bf = bill.get("broughtForward")
    pmt = bill.get("payments")
    out = bill.get("outstandingBalance")
    if bf is not None and pmt is not None and out is not None:
        if (bf - pmt) != out:
            warnings.append(f"Outstanding Balance Discrepancy: {bf} - {pmt} = {bf - pmt} != {out}")

    # 4. Monthly Bill reconciliation: Charge + Levy == Monthly Bill
    ch = bill.get("energyCharge")
    lev = bill.get("levyAmount")
    mb = bill.get("monthlyBill")
    if ch is not None and lev is not None and mb is not None:
        if (ch + lev) != mb:
            warnings.append(f"Monthly Bill Discrepancy: {ch} + {lev} = {ch + lev} != {mb}")

    # 5. Total Due reconciliation: Outstanding + Monthly Bill == Total Due
    tot = bill.get("totalDue")
    if out is not None and mb is not None and tot is not None:
        if (out + mb) != tot:
            warnings.append(f"Total Due Discrepancy: {out} + {mb} = {out + mb} != {tot}")

    return warnings

def run_tests():
    print("=================================================================")
    print("           SRI LANKAN ELECTRICITY BILL RECOGNITION TEST          ")
    print("=================================================================")

    # Test 1: Standard CEB e-Bill from WhatsApp with header chrome
    raw_whatsapp_bill = """
    Forwarded
    00:38
    CEB e-Bill
    A/C No: 5410264908 (D1)
    R RANJITH
    B/F: Rs. 2,987.07
    Payments: Rs. 2,200.00
    Outstanding: Rs. 787.07 by 2026-09-17
    Reading Date: 2026-09-30 (457)
    Reading: 10756 - 10678 = 78 Units
    Charge: Rs. 1,588.00
    SSC Levy: Rs. 40.72
    Monthly Bill: Rs. 1,628.72
    Total Due: Rs. 2,415.79
    Open this link to view your electricity bill.
    https://ebill.edl.lk/v1/NTQxMDI2NDkwOCo0NTcqNTg2
    """
    lines = [l.strip() for l in raw_whatsapp_bill.strip().split("\n") if l.strip()]
    filtered = filter_messaging_chrome(lines)
    fmt = detect_format(filtered)
    assert fmt == BillFormatType.CEB_E_BILL, f"Format detected as {fmt}"
    
    parsed = parse_ceb_e_bill(filtered)
    print("Parsed CEB e-Bill:")
    for k, v in parsed.items():
        print(f"  - {k}: {v}")

    assert parsed["accountNumber"] == "5410264908", f"Account: {parsed['accountNumber']}"
    assert parsed["tariffCode"] == "D1", f"Tariff: {parsed['tariffCode']}"
    assert parsed["customerName"] == "R RANJITH", f"Name: {parsed['customerName']}"
    assert parsed["broughtForward"] == Decimal("2987.07")
    assert parsed["payments"] == Decimal("2200.00")
    assert parsed["outstandingBalance"] == Decimal("787.07")
    assert parsed["outstandingDueDate"] == "2026-09-17"
    assert parsed["readingDate"] == "2026-09-30"
    assert parsed["readingDateSuffix"] == "457", f"Suffix: {parsed['readingDateSuffix']}"
    assert parsed["currentReading"] == 10756
    assert parsed["previousReading"] == 10678
    assert parsed["consumptionUnits"] == 78
    assert parsed["energyCharge"] == Decimal("1588.00")
    assert parsed["levyAmount"] == Decimal("40.72")
    assert parsed["monthlyBill"] == Decimal("1628.72")
    assert parsed["totalDue"] == Decimal("2415.79")
    assert "ebill.edl.lk" in parsed["billURL"]

    warnings = validate_bill(parsed)
    print("\nValidation warnings for clean CEB e-Bill:", warnings)
    assert len(warnings) == 0, f"Expected 0 warnings, got: {warnings}"
    print("[PASS] Test 1: Standard CEB e-Bill with WhatsApp Chrome passed with 100% precision!\n")

    # Test 2: CEB e-Bill with typical OCR noise (O->0, l->1, S->5, B->8)
    ocr_noisy_bill = """
    CEB e-Bill
    A/C No: 54lO2649O8 (D1)
    K PERERA
    B/F: Rs. 2,987.O7
    Payments: Rs. 2,2OO.OO
    Outstanding: Rs. 787.O7 by 2O26-O9-17
    Reading Date: 2O26-O9-3O (457)
    Reading: lO756 - lO678 = 78 Units
    Charge: Rs. 1,S88.OO
    SSC Levy: Rs. 4O.72
    Monthly Bill: Rs. 1,628.72
    Total Due: Rs. 2,415.79
    """
    lines2 = [l.strip() for l in ocr_noisy_bill.strip().split("\n") if l.strip()]
    parsed2 = parse_ceb_e_bill(lines2)
    print("Parsed Noisy Bill (after token disambiguation):")
    print(f"  - Cleaned Account: {parsed2['accountNumber']}")
    print(f"  - Cleaned Reading Date: {parsed2['readingDate']}")
    print(f"  - Cleaned Outstanding Date: {parsed2['outstandingDueDate']}")
    print(f"  - Cleaned Charge: {parsed2['energyCharge']}")
    print(f"  - Cleaned Levy: {parsed2['levyAmount']}")
    print(f"  - Cleaned Readings: {parsed2['currentReading']} - {parsed2['previousReading']} = {parsed2['consumptionUnits']}")
    
    assert parsed2["accountNumber"] == "5410264908", f"Cleaned acct: {parsed2['accountNumber']}"
    assert parsed2["customerName"] == "K PERERA"
    assert parsed2["currentReading"] == 10756
    assert parsed2["previousReading"] == 10678
    assert parsed2["consumptionUnits"] == 78
    assert parsed2["energyCharge"] == Decimal("1588.00")
    assert parsed2["levyAmount"] == Decimal("40.72")
    assert parsed2["readingDate"] == "2026-09-30"
    assert parsed2["outstandingDueDate"] == "2026-09-17"
    warnings2 = validate_bill(parsed2)
    assert len(warnings2) == 0, f"Expected 0 warnings, got {warnings2}"
    print("[PASS] Test 2: OCR Character Disambiguation (O->0, l->1, S->5, B->8) passed!\n")

    # Test 3: Printed CEB Bill
    printed_bill = """
    CEYLON ELECTRICITY BOARD
    Statement of Electricity Account
    Account No: 1847291845
    Customer Name: Nimal Silva
    Tariff Category: D1
    Reading Date: 2026-08-31
    Due Date: 2026-09-21
    Reading: 12630 - 12450 = 180 Units
    Electricity Charge: Rs. 6,850.00
    SSC Levy: Rs. 150.00
    Monthly Bill: Rs. 7,000.00
    Total Due: Rs. 7,000.00
    """
    lines3 = [l.strip() for l in printed_bill.strip().split("\n") if l.strip()]
    parsed3 = parse_printed_or_standard_bill(lines3)
    print("Parsed Printed CEB Bill:")
    for k, v in parsed3.items():
        print(f"  - {k}: {v}")
    assert parsed3["provider"] == "Ceylon Electricity Board (CEB)"
    assert parsed3["accountNumber"] == "1847291845"
    assert parsed3["customerName"] == "Nimal Silva"
    assert parsed3["tariffCode"] == "D1"
    assert parsed3["readingDate"] == "2026-08-31"
    assert parsed3["currentReading"] == 12630
    assert parsed3["previousReading"] == 12450
    assert parsed3["consumptionUnits"] == 180
    assert parsed3["energyCharge"] == Decimal("6850.00")
    assert parsed3["levyAmount"] == Decimal("150.00")
    assert parsed3["totalDue"] == Decimal("7000.00")
    warnings3 = validate_bill(parsed3)
    assert len(warnings3) == 0, f"Expected 0 warnings, got {warnings3}"
    print("[PASS] Test 3: Printed CEB Bill parsing and reconciliation passed!\n")

    # Test 4: LECO Bill
    leco_bill = """
    LANKA ELECTRICITY COMPANY (LECO)
    Account No: 0823456789
    Name: Suneth Jayasuriya
    Tariff Code: D1
    Bill Date: 2026-07-28
    Due Date: 2026-08-18
    Previous Meter Reading: 8420
    Current Meter Reading: 8560
    Units Consumed: 140
    Energy Charge: Rs. 5,200.00
    Levy: Rs. 120.00
    Monthly Bill: Rs. 5,320.00
    Total Due: Rs. 5,320.00
    """
    lines4 = [l.strip() for l in leco_bill.strip().split("\n") if l.strip()]
    parsed4 = parse_printed_or_standard_bill(lines4)
    print("Parsed LECO Bill:")
    for k, v in parsed4.items():
        print(f"  - {k}: {v}")
    assert parsed4["provider"] == "Lanka Electricity Company (LECO)"
    assert parsed4["accountNumber"] == "0823456789"
    assert parsed4["customerName"] == "Suneth Jayasuriya"
    assert parsed4["tariffCode"] == "D1"
    assert parsed4["readingDate"] == "2026-07-28"
    assert parsed4["previousReading"] == 8420
    assert parsed4["currentReading"] == 8560
    assert parsed4["consumptionUnits"] == 140
    assert parsed4["energyCharge"] == Decimal("5200.00")
    assert parsed4["levyAmount"] == Decimal("120.00")
    assert parsed4["totalDue"] == Decimal("5320.00")
    warnings4 = validate_bill(parsed4)
    assert len(warnings4) == 0, f"Expected 0 warnings, got {warnings4}"
    print("[PASS] Test 4: LECO Bill parsing and reconciliation passed!\n")

    # Test 5: Math Discrepancy Detection in Validator
    bad_math_bill = dict(parsed)
    bad_math_bill["consumptionUnits"] = 100  # 10756 - 10678 is 78, not 100
    bad_math_bill["monthlyBill"] = Decimal("2000.00")  # 1588.00 + 40.72 is 1628.72
    warnings5 = validate_bill(bad_math_bill)
    print("Validation warnings for math mismatch bill:", warnings5)
    assert any("Meter Reading Discrepancy" in w for w in warnings5)
    assert any("Monthly Bill Discrepancy" in w for w in warnings5)
    print("[PASS] Test 5: Mathematical Reconciliation correctly flags discrepancies!\n")

    # Test 6: Inconsistent Meter Readings (Current < Previous)
    inverted_readings_bill = dict(parsed)
    inverted_readings_bill["currentReading"] = 10000
    inverted_readings_bill["previousReading"] = 10500
    warnings6 = validate_bill(inverted_readings_bill)
    print("Validation warnings for inverted readings:", warnings6)
    assert any("Inconsistent Meter Readings" in w for w in warnings6)
    print("[PASS] Test 6: Inverted meter readings detected successfully!\n")

    print("=================================================================")
    print("    ALL BILL RECOGNITION TESTS PASSED WITH 100% ACCURACY! (6/6)  ")
    print("=================================================================")

if __name__ == "__main__":
    run_tests()
