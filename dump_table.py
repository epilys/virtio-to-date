from sqlite_utils import Database
from tabulate import tabulate
import sys

db = Database("virtio-to-date.db")

standard_versions = {}
for row in db["virtio_standard_version"].rows:
    standard_versions[row["name"]] = row["url"]


def generate_backend_support(db, standard_versions) -> str:
    device_support = {}
    stacks = {}

    for row in db["virtualization_stack"].rows:
        stacks[row["short_name"]] = row

    for row in db.query(
        """select
      d.id as id,
      d.short_name as device,
      d.name as name,
      d.introduced_in as standardized
    from
      virtio_device as d
    where d.short_name IS NOT NULL
      order by d.id;"""
    ):
        standardized = row["standardized"]
        if standardized:
            standardized = (
                f'<a href="{standard_versions[standardized]}">{standardized}</a>'
            )
        device_support[row["device"]] = {
            "id": row["id"],
            "name": row["name"],
            "standardized": standardized,
        }
        for vmm in stacks:
            device_support[row["device"]][vmm] = False

    for vmm in stacks:
        for row in db.query(
            f"""select
          d.short_name as device
        from
          virtio_device as d,
          virtualization_stack as vmm,
          virtio_device_backend as b
        where
          d.id = b.device_id
          and b.software = vmm.short_name
          and vmm.short_name = '{vmm}'
        order by d.id;"""
        ):
            if row["device"]:
                device_support[row["device"]][vmm] = True

    to_emoji = lambda x: "✅" if x else "❌"

    headers = ["device", "standardized in"] + [stacks[vmm]["name"] for vmm in stacks]
    rows = [
        (
            [
                f"<data value=\"{device_support[d]['id']}\"><code title=\"ID: {device_support[d]['id']}\">{d}</code></data>",
                device_support[d]["standardized"] or "❌",
            ]
            + [to_emoji(device_support[d][vmm]) for vmm in stacks]
        )
        for d in device_support
    ]
    return tabulate(rows, headers=headers, tablefmt="unsafehtml")


def generate_driver_support(db, standard_versions) -> str:
    driver_support = {}
    oses = {}
    for row in db["operating_system"].rows:
        oses[row["short_name"]] = row

    for row in db.query(
        """select
      d.id as id,
      d.short_name as device,
      d.introduced_in as standardized
    from
      virtio_device as d
    where d.short_name IS NOT NULL
      order by d.id;"""
    ):
        standardized = row["standardized"]
        if standardized:
            standardized = (
                f'<a href="{standard_versions[standardized]}">{standardized}</a>'
            )
        driver_support[row["device"]] = {
            "id": row["id"],
            "standardized": standardized,
        }
        for os in oses:
            driver_support[row["device"]][os] = False

    for os in oses:
        for row in db.query(
            f"""select
          d.short_name as device
        from
          virtio_device as d,
          operating_system as os,
          virtio_device_driver as b
        where
          d.id = b.device_id
          and b.software = os.short_name
          and os.short_name = '{os}'
        order by d.id;"""
        ):
            if row["device"]:
                driver_support[row["device"]][os] = True

    to_emoji = lambda x: "✅" if x else "❌"

    notes = []
    headers = ["device", "standardized in"]

    for os in oses:
        if oses[os]["notes"]:
            notes.append(oses[os])

            headers.append(
                f"<a href=\"{oses[os]['url']}\" title=\"{oses[os]['notes']}\">{oses[os]['name']}</a> (*)"
            )
        else:
            headers.append(f"<a href=\"{oses[os]['url']}\">{oses[os]['name']}</a>")

    rows = [
        (
            [
                f"<data value=\"{driver_support[d]['id']}\"><code title=\"ID: {driver_support[d]['id']}\">{d}</code></data>",
                driver_support[d]["standardized"] or "❌",
            ]
            + [to_emoji(driver_support[d][os]) for os in oses]
        )
        for d in driver_support
    ]
    return tabulate(rows, headers=headers, tablefmt="unsafehtml")


html_start = """
<!DOCTYPE html>
<html lang='en'>
 <head>
  <title>QEMU virtio device support</title>
  <meta charset='utf-8'>
  <style>
html {
  font-family: "Helvetica", "Arial", sans-serif;
}

data:hover::after {
  content: " (ID " attr(value) ")";
  font-size: 0.7em;
}

table {
  table-layout: fixed;
  width: 90%;
  margin: 10px auto;
  border-collapse: collapse;
  border-top: 1px solid #999999;
  border-bottom: 1px solid #999999;
}

th,
td {
  vertical-align: top;
  padding: 0.6em;
}

tr {
  text-align: left;
}

tr :nth-child(2),
tr :nth-child(3) {
  width: 15%;
}

tr :nth-child(1),
tr :nth-child(4) {
  width: 15%;
}

tfoot {
  border-top: 1px solid #999999;
}

tbody tr:nth-child(odd) {
  background-color: #eeeeee;
}

caption {
  padding: 1em;
  font-style: italic;
  caption-side: bottom;
  letter-spacing: 1px;
}

  </style>
  <script>
  </script>
 </head>
 <body>
 """

html_end = """
 </body>
</html>
"""

print(html_start)
print(generate_backend_support(db, standard_versions))
print(generate_driver_support(db, standard_versions))
print(html_end)
