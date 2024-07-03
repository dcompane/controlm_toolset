# Control-M Kafka Read2File plugin

## Changes on this version

| Date       | Who               | What               |
| ---------- | ----------------- | ------------------ |
| 2024-06-29 | Daniel Companeetz | Initial deployment |
|            |                   |                    |

## Detailed Description

This Control-M Application Integrator job type enables the automation of reading a Kafka topic's mesage and storing the payload as a file

The job type is created as a python script that accesses Kafka using the conluent-kafka python package (v2.4.0)

The code follows the code at [Python Client code examples -> Basic poll loop](https://docs.confluent.io/kafka-clients/python/current/overview.html#basic-poll-loop) a of 2024-06-26

The AI plug-in requires the python package confluent-kafka. It can be installed by running

```python
pip install confluent-kafka
```

For now, the AI plugin will only run on Linux, as uses the heredoc funcionality to run the python code embedded in the AI step.code. and this template can be easily adapted to other shells as needed.

The objective of this fully functional module is to show how easy it is to configure a job type based on any application that has an available API, in this case implemented by the confluent-kafka package.

There is a provision to end the loop after a certain time, with a default on 15 minutes. If the duration is 0 (zero), the duration is calculated to 23hrs 59 mins. This is to allow for the job to finish at some point during the next day. 

NOTE: If the job is re-run, the long duration can cause issues. I recommend to use a cycle time of 15 minutes and use a cyclic job.

## Download

* [Click this to download a zip of the PlugIn jobtype](https://github.com/dcompane/controlm_toolset/blob/main/misc_tools/Kafka/Resources/DCO_KAFKA.zip)

  Click download and unzip the archive. Then, import the file into the Application Integrator designer.

* [Click this for the uncompressed raw DCO_Kafka.ctmai file](https://github.com/dcompane/controlm_toolset/blob/main/misc_tools/Kafka/Resources/DCO_KAFKA.ctmai)

  This will allow you to retrieve the raw ctmai file as described in the repository [Readme](https://github.com/controlm/integrations-plugins-community-solutions#saving-application-integrator-files-for-use).

* Or use the following command:

  ```bash
  wget -O DCO_KAFKA.ctmai https://github.com/dcompane/controlm_toolset/blob/main/misc_tools/Kafka/Resources/DCO_KAFKA.ctmai
  ```

## Fields and available actions

### Connection Profile

{
  "DCO_KAFKA_DC01": {
    "Type": "ConnectionProfile:ApplicationIntegrator:AI DCO_Kafka",
    "AI-Group ID": "test",
    "AI-bootstrap port": "9092",
    "AI-bootstrap-server": "dc01",
    "Description": "",
    "Centralized": true
  }
}

### Kafka Job Form

"AI DCO_Kafka_Job_2": {
    "Type": "Job:ApplicationIntegrator:AI DCO_Kafka",
    "ConnectionProfile": "DCO_KAFKA_DC01",
    "AI-Job Duration": "5",
    "AI-Topic": "test",
    "AI-file path": "/tmp",
    "AI-file name prefix": "DCO",
    "AI-file name body": "%%ORDERID._%%RUNCOUNT"
}
(ONLY RELEVANT FIELDS SHOWN )

## Additional Information

There will be no output until the job ends.

It is possible that an initial connection refused message is seen, but that does not mean the job will fail

```text
%3|1719709861.182|FAIL|rdkafka#consumer-1| [thrd:dc01:9092/bootstrap]: dc01:9092/bootstrap: Connect to ipv4#127.0.0.1:9092 failed: \
Connection refused (after 0ms in state CONNECT)
```

For future development: use python -u instead of plain python.
See Why at [https://bugs.python.org/issue41449](Python issue 41449)
And see HowTo at [https://stackoverflow.com/questions/107705/disable-output-buffering ](Stackoverflow on buffering STDOUT on Python)

## Requirements

Control-M/Agent with Control-M Application Integrator plug-in installed, running on Unix/Linux.

Tested with Helix Control-M agent.

## Platforms and versions

The job was created and tested with the following platforms and versions:

Helix Control-M, and Helix Control-M Agent running on Linux.

```text
    There is no reason it should not be compatible with Control-M 9.0.21.
```
