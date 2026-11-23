"""Estimate what requested and used resources cost on one node type (illustrative inputs)."""
import json
import sys


def main():
    if len(sys.argv) != 2:
        print("usage: python cost_model.py <inputs.json>")
        return 2
    with open(sys.argv[1], encoding="utf-8") as handle:
        data = json.load(handle)
    node = data["node"]
    month = node["price_per_hour"] * data["hours_per_month"]
    cpu_price = month * data["cpu_share"] / node["vcpu"]
    memory_price = month * (1 - data["cpu_share"]) / node["memory_gib"]
    print(f"Node: {month:.2f} per month; {cpu_price:.2f} per vCPU, {memory_price:.2f} per GiB")
    total = {"requested": 0.0, "used": 0.0, "cpu": 0.0, "memory": 0.0}
    for item in data["workloads"]:
        replicas = item["replicas"]
        request_cpu = replicas * item["cpu_request_m"] / 1000
        request_memory = replicas * item["memory_request_mib"] / 1024
        used_cpu = replicas * item["cpu_used_p95_m"] / 1000
        used_memory = replicas * item["memory_used_p95_mib"] / 1024
        requested = request_cpu * cpu_price + request_memory * memory_price
        used = used_cpu * cpu_price + used_memory * memory_price
        slack = (requested - used) / requested * 100 if requested else 0.0
        print(f"{item['name']:<8} requested {requested:.2f} used {used:.2f} slack {slack:.1f}%")
        total["requested"] += requested
        total["used"] += used
        total["cpu"] += request_cpu
        total["memory"] += request_memory
    slack = (total["requested"] - total["used"]) / total["requested"] * 100 if total["requested"] else 0.0
    print(f"{'total':<8} requested {total['requested']:.2f} used {total['used']:.2f} slack {slack:.1f}%")
    cpu_fill = total["cpu"] / node["vcpu"] * 100
    memory_fill = total["memory"] / node["memory_gib"] * 100
    print(f"Requests fill {cpu_fill:.1f}% of the node's CPU and {memory_fill:.1f}% of its memory")
    return 0


if __name__ == "__main__":
    sys.exit(main())
