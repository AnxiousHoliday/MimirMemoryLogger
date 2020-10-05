import sys
import json
from beautifultable import BeautifulTable
from datetime import datetime

if __name__ == '__main__':
    logs_file_location = sys.argv[1]
    with open(logs_file_location) as json_file:
        data = json.load(json_file)
        date_snapshot_was_taken = data['dateSnapshotWasTaken']
        total_size = data['totalSize']
        objects_in_memory = data['objectsInMemory']
        table = BeautifulTable(maxwidth=150)
        table.set_style(BeautifulTable.STYLE_BOX_ROUNDED)
        for object in objects_in_memory:
            table.rows.append([object['className'], object['totalSize'], object['numberOfInstances'], object['maxSingleInstanceSize']])
        table.columns.header = ['className', 'totalSize', 'numberOfInstances', 'maxSingleInstanceSize']

        table.columns.width['className'] = 50
        table.columns.alignment['className'] = BeautifulTable.ALIGN_LEFT
        table.columns.alignment['totalSize'] = BeautifulTable.ALIGN_LEFT
        table.columns.alignment['numberOfInstances'] = BeautifulTable.ALIGN_LEFT
        table.columns.alignment['maxSingleInstanceSize'] = BeautifulTable.ALIGN_LEFT
        table.rows.sort('totalSize', reverse=True)
        print(table)
        print("🔵 sizes are in bytes")
        print("🟣 total_size = " + str(total_size))
        print("🟡 date_snapshot_was_taken = " + str(datetime.fromtimestamp(date_snapshot_was_taken)))

