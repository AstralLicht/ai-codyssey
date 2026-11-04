import csv
import os
from datetime import date

FILE = "attendance.csv"


def load():
    """CSV 파일에서 출석 데이터를 읽어온다."""
    if not os.path.exists(FILE):
        return []
    with open(FILE, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return list(reader)


def save(records):
    """출석 데이터를 CSV 파일에 저장한다."""
    with open(FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["date", "name"])
        writer.writeheader()
        writer.writerows(records)


def add(records):
    """날짜와 이름을 입력받아 출석을 추가한다."""
    today = date.today().isoformat()
    date_input = input(f"날짜 (엔터 = 오늘 {today}): ").strip()
    if not date_input:
        date_input = today

    name = input("이름: ").strip()
    if not name:
        print("⚠️  이름을 입력해주세요.")
        return records

    records.append({"date": date_input, "name": name})
    save(records)
    print(f"✅  {date_input} / {name} 출석 완료!")
    return records


def list_all(records):
    """저장된 출석 목록을 출력한다."""
    if not records:
        print("📭  출석 기록이 없습니다.")
        return

    print(f"\n{'날짜':<16}{'이름'}")
    print("-" * 28)
    for r in records:
        print(f"{r['date']:<16}{r['name']}")
    print(f"\n총 {len(records)}건")


def main():
    records = load()

    while True:
        print("\n=== 출석부 ===")
        print("1. 출석 입력")
        print("2. 목록 보기")
        print("3. 종료")
        choice = input("선택: ").strip()

        if choice == "1":
            records = add(records)
        elif choice == "2":
            list_all(records)
        elif choice == "3":
            print("👋  종료합니다.")
            break
        else:
            print("⚠️  1, 2, 3 중에서 선택해주세요.")


if __name__ == "__main__":
    main()
