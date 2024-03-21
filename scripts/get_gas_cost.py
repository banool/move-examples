import argparse
import logging
import sys
import urllib.request
import json


logging.basicConfig(level="INFO", format="%(asctime)s - %(levelname)s - %(message)s")


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--debug", action="store_true")
    parser.add_argument("--sender-address")
    parser.add_argument("--entry-function-id-str")
    parser.add_argument("--network", required=True, default="mainnet")
    args = parser.parse_args()
    return args


QUERY = """
query MyQuery {
  user_transactions(
    where: { {where} }
    offset: {offset}
    limit: {limit}
  ) {
    version
  }
}
"""


def build_query(sender_address, entry_function_id_str, offset, limit):
    where = []
    if sender_address:
        where.append(f'sender: {{_eq: "{sender_address}"}}')
    if entry_function_id_str:
        where.append(f'entry_function_id_str: {{_eq: "{entry_function_id_str}"}}')
    where_str = ", ".join(where)
    return (
        QUERY.replace("{where}", where_str)
        .replace("{offset}", str(offset))
        .replace("{limit}", str(limit))
    )


def get_batch_of_transactions(sender_address, entry_function_id_str, offset, limit):
    query = build_query(sender_address, entry_function_id_str, offset, limit)
    logging.info(f"Making query: {query}")

    indexer_url = f"https://api.mainnet.aptoslabs.com/v1/graphql"

    query = {"query": query, "variables": None, "operationName": "MyQuery"}

    # Look up the transaction versions.
    req = urllib.request.Request(indexer_url)
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")
    response = urllib.request.urlopen(req, json.dumps(query).encode())
    data = json.loads(response.read())
    return data["data"]["user_transactions"]


def get_transactions(sender_address, entry_function_id_str):
    limit = 99
    offset = 0
    while True:
        versions = get_batch_of_transactions(
            sender_address, entry_function_id_str, offset, limit
        )
        if not versions:
            break
        for version in versions:
            yield version
        offset += limit


def get_gas_cost(txn_version):
    url = f"https://api.mainnet.aptoslabs.com/v1/transactions/by_version/{txn_version}"
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/json")
    response = urllib.request.urlopen(req)
    data = json.loads(response.read())
    return int(data["gas_used"])


def main():
    args = parse_args()

    if args.debug:
        logging.setLevel("DEBUG")

    if args.sender_address is None and args.entry_function_id_str is None:
        logging.error(
            "Provide at least one of --sender-address and --entry-function-id-str"
        )
        return 1

    # Look up the transaction versions.
    transactions = get_transactions(args.sender_address, args.entry_function_id_str)
    versions = [txn["version"] for txn in transactions]

    logging.info(f"Found {len(versions)} transactions")

    # Look up the gas costs.
    total_gas_cost = 0
    for version in versions:
        logging.info(f"Getting gas cost for version {version}")
        gas_cost = get_gas_cost(version)
        total_gas_cost += gas_cost

    logging.info(f"Total gas cost: {total_gas_cost} (OCTA)")
    logging.info(f"Total gas cost: {total_gas_cost / 1e8} (APT)")


if __name__ == "__main__":
    sys.exit(main())
