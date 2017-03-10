#!/usr/bin/env python3

import os
import json

if __name__ == "__main__":
    qmlfiles = []
    for subdir, dirs, files in os.walk("."):
        for file in files:
            filepath = subdir + os.sep + file
            if filepath.endswith(".qml"):
                qmlfiles.append(filepath.split("/")[-1])

    content = {
    "annotations": {
      "list": []
    },
    "editable": True,
    "gnetId": None,
    "graphTooltip": 0,
    "hideControls": False,
    "id": None,
    "links": [],
    "schemaVersion": 14,
    "style": "dark",
    "tags": [],
    "templating": {
      "list": []
    },
    "time": {
      "from": "now-7d",
      "to": "now"
    },
    "timepicker": {
      "refresh_intervals": [
        "5s",
        "10s",
        "30s",
        "1m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "1d"
      ],
      "time_options": [
        "5m",
        "15m",
        "1h",
        "6h",
        "12h",
        "24h",
        "2d",
        "7d",
        "30d"
      ]
    },
    "timezone": "browser",
    "title": "New dashboard",
    "version": 0
    }

    panelId = 0
    rows = []
    for qmlfile in qmlfiles:
        panelId += 1
        panels = [
            {
                "aliasColors": {},
                "bars": False,
                "datasource": "qmlbench",
                "fill": 1,
                "id": panelId,
                "legend": {
                        "avg": False,
                        "current": False,
                        "max": False,
                        "min": False,
                        "show": True,
                        "total": False,
                        "values": False,
                },
                "lines": True,
                "linewidth": 1,
                "links": [],
                "nullPointMode": "null",
                "percentage": False,
                "pointradius": 5,
                "points": True,
                "renderer": "flot",
                "seriesOverride": [],
                "span": 12,
                "stack": False,
                "steppedLine": False,
                "targets": [
                    {
                        "dsType": "influxdb",
                        "groupBy": [
                            {
                                "params": [
                                    "qtVersion"
                                ],
                                "type": "tag"
                            }
                        ],
                        "measurement": qmlfile,
                        "policy": "default",
                        "refId": "A",
                        "resultFormat": "time_series",
                        "select": [
                                [
                                    {
                                        "params": [
                                            "mean"
                                        ],
                                        "type": "field"
                                    }
                                ]
                        ],
                        "tags": [
                            {
                                "key": "osVersion",
                                "operator": "=",
                                "value": "Ubuntu.15.04"
                            }
                        ]
                    }
                ],
                "thresholds": [],
                "timeFrom": None,
                "timeShift": None,
                "title": qmlfile,
                "tooltip": {
                "shared": True,
                "sort": 0,
                "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
                "mode": "time",
                "name": None,
                "show": True,
                "values": []
            },
            "yaxes": [
                {
                    "format": "short",
                    "label": None,
                    "logBase": 1,
                    "max": None,
                    "min": "0",
                    "show": True
                },
                {
                    "format": "short",
                    "label": None,
                    "logBase": 1,
                    "max": None,
                    "min": None,
                    "show": True
                }
            ]
            }
        ]
        row = { "collapse": False,
                "height": "250px",
                "repeat": None,
                "repeatIteration": None,
                "repeatRowId": None,
                "showTitle": False,
                "title": "A Row",
                "titleSize": "h6",
                "panels": panels
        }
        rows.append(row)

        table = {
              "collapse": False,
              "height": 250,
              "panels": [
                {
                  "columns": [],
                  "datasource": "qmlbench",
                  "fontSize": "100%",
                  "id": 2,
                  "links": [],
                  "pageSize": None,
                  "scroll": True,
                  "showHeader": True,
                  "sort": {
                    "col": 0,
                    "desc": True
                  },
                  "span": 12,
                  "styles": [
                    {
                      "dateFormat": "YYYY-MM-DD HH:mm:ss",
                      "pattern": "Time",
                      "type": "date"
                    },
                    {
                      "colorMode": None,
                      "colors": [
                        "rgba(245, 54, 54, 0.9)",
                        "rgba(237, 129, 40, 0.89)",
                        "rgba(50, 172, 45, 0.97)"
                      ],
                      "decimals": 2,
                      "pattern": "/.*/",
                      "thresholds": [],
                      "type": "number",
                      "unit": "short"
                    }
                  ],
                  "targets": [
                    {
                      "dsType": "influxdb",
                      "groupBy": [],
                      "measurement": qmlfile,
                      "policy": "default",
                      "refId": "A",
                      "resultFormat": "time_series",
                      "select": [
                        [
                          {
                            "params": [
                              "mean"
                            ],
                            "type": "field"
                          }
                        ],
                        [
                          {
                            "params": [
                              "coefficientOfVariation"
                            ],
                            "type": "field"
                          }
                        ],
                        [
                          {
                            "params": [
                              "qtBaseHead"
                            ],
                            "type": "field"
                          }
                        ],
                        [
                          {
                            "params": [
                              "qtDeclarativeHead"
                            ],
                            "type": "field"
                          }
                        ]
                      ],
                      "tags": [
                        {
                          "key": "osVersion",
                          "operator": "=",
                          "value": "Ubuntu.15.04"
                        }
                      ]
                    }
                  ],
                  "title": qmlfile,
                  "transform": "timeseries_to_columns",
                  "type": "table"
                }
              ],
              "repeat": None,
              "repeatIteration": None,
              "repeatRowId": None,
              "showTitle": False,
              "title": "Dashboard Row",
              "titleSize": "h6"
            }
        rows.append(table)

    content["rows"] = rows
    print(json.dumps(content))
