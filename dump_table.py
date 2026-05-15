from sqlite_utils import Database
from tabulate import tabulate
from datetime import date
import sys

today = date.today().strftime("%Y-%m-%d")

db = Database("virtio-to-date.db")

standard_versions = {}
for row in db["virtio_standard_version"].rows:
    standard_versions[row["name"]] = row["url"]


def generate_devices(db, standard_versions) -> str:
    devices = {}

    for row in db["virtio_device"].rows:
        id_reserved_in = row["id_reserved_in"]
        id_reserved_in = (
            f'<a href="{standard_versions[id_reserved_in]}">{id_reserved_in}</a>'
        )
        introduced_in = row["introduced_in"]
        if introduced_in:
            introduced_in = (
                f'<a href="{standard_versions[introduced_in]}">{introduced_in}</a>'
            )
        else:
            introduced_in = "❌"

        devices[row["id"]] = {
            "name": row["name"],
            "short_name": row["short_name"],
            "id_reserved_in": id_reserved_in,
            "introduced_in": introduced_in,
        }

    headers = ["device id", "device", "ID reserved in", "Introduced in"]
    rows = [
        (
            [
                d,
                (
                    f"{devices[d]['name']} (<i>{devices[d]['short_name']}</i>)"
                    if devices[d]["short_name"]
                    else f"{devices[d]['name']}"
                ),
                devices[d]["id_reserved_in"],
                devices[d]["introduced_in"],
            ]
        )
        for d in devices
    ]
    return tabulate(rows, headers=headers, tablefmt="unsafehtml")


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
            device_support[row["device"]][vmm] = {
                "status": False,
                "url": None,
                "notes": None,
            }

    for vmm in stacks:
        for row in db.query(
            f"""select
          d.short_name as device,
          b.url as url,
          b.notes as notes
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
                device_support[row["device"]][vmm]["status"] = True
                if row["url"]:
                    device_support[row["device"]][vmm]["url"] = row["url"]
                if row["notes"]:
                    device_support[row["device"]][vmm]["notes"] = row["notes"]

    def to_entry(vmm_support) -> str:
        if not vmm_support["status"]:
            return "❌"
        url = vmm_support["url"]
        notes = vmm_support["notes"]
        if url and not notes:
            return f'<a href="{url}">{url}</a>'
        if notes and not url:
            return notes
        if not url and not notes:
            return "✅"
        return f'<a href="{url}">{url}</a> ({notes})'

    headers = ["device", "standardized in"] + [stacks[vmm]["name"] for vmm in stacks]
    rows = [
        (
            [
                f"<data value=\"{device_support[d]['id']}\"><code title=\"ID: {device_support[d]['id']}\">{d}</code></data>",
                device_support[d]["standardized"] or "❌",
            ]
            + [to_entry(device_support[d][vmm]) for vmm in stacks]
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


html_start = (
    """
<!DOCTYPE html>
<html lang='en'>
 <head>
  <title>virtio-to-date</title>
  <meta charset='utf-8'>
  <style>
html {
  font-family: system-ui, "Helvetica", "Arial", sans-serif;
  -moz-text-size-adjust: none;
  -webkit-text-size-adjust: none;
  text-size-adjust: none;
  font-size: 100%;
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
 <header>
 <h1 id="top">virtio-to-date</h1>
 <p>Best-effort current status of VIRTIO spec and VIRTIO implementations (drivers and backends for devices/transports). To suggest a change, <a href="https://github.com/epilys/virtio-to-date">submit a PR</a>. Generated on: <time datetime="""
    + f'{today}">{today}'
    + """</time></p>
 </header>
 <h2 id="toc">Table of contents</h2>
<nav>
  <ul>
    <li><a href="#devices">Devices</a></li>
    <li><a href="#device-backends">Device backends</a></li>
    <li><a href="#device-frontends">Device frontends (drivers)</a></li>
  </ul>
</nav>
 """
)

html_end = """
 </body>
</html>
"""

print(html_start)
print('<h2 id="devices">Devices</h2>')
print(generate_devices(db, standard_versions))
print('<h2 id="device-backends">Device backends</h2>')
print(generate_backend_support(db, standard_versions))
print('<h2 id="device-frontends">Device frontends (drivers)</h2>')
print(generate_driver_support(db, standard_versions))
print(html_end)
