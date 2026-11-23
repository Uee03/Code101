"""Print a dry-run retention plan: keep deployed images and the newest N, delete the rest."""
import json
import sys


def plan(inventory):
    images = inventory["images"]
    by_age = sorted(images, key=lambda item: item["pushed"], reverse=True)
    newest = {item["tag"] for item in by_age[: inventory["keep_latest"]]}
    results = []
    for item in sorted(images, key=lambda item: item["pushed"]):
        if item["environments"]:
            results.append(("KEEP", item, "deployed to " + ", ".join(item["environments"])))
        elif item["tag"] in newest:
            results.append(("KEEP", item, f"one of the newest {inventory['keep_latest']}"))
        else:
            results.append(("DELETE", item, "not deployed and not among the newest"))
    return results


def main():
    if len(sys.argv) != 2:
        print("usage: python retention_plan.py <inventory.json>")
        return 2
    with open(sys.argv[1], encoding="utf-8") as handle:
        inventory = json.load(handle)
    results = plan(inventory)
    print(f"Repository {inventory['repository']}: keep the newest {inventory['keep_latest']} plus anything deployed")
    for verdict, item, reason in results:
        print(f"{verdict:<6} {item['tag']:<6} {item['pushed']}  {reason}")
    deletes = sum(1 for verdict, _, _ in results if verdict == "DELETE")
    print(f"Dry run: {deletes} to delete, {len(results) - deletes} to keep. Nothing was changed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
