# Neo4j Setup

This guide explains how to set up Neo4j for the project using either **Neo4j Desktop** or **Neo4j AuraDB**. It also covers connecting to Neo4j through the Python Driver.

---

## Requirements

The project uses:

* Neo4j Desktop **or** Neo4j AuraDB
* Python 3.10+
* Neo4j Python Driver

---

# Option 1: Neo4j Desktop

Neo4j Desktop runs the database locally on your computer.

## 1. Install Neo4j Desktop

[Download Neo4j Desktop](https://neo4j.com/download/?utm_source=GSearch&utm_medium=PaidSearch&utm_campaign=Evergreen&utm_content=AMS-Search-SEMBrand-Evergreen-None-SEM-SEM-NonABM&utm_term=install%20neo4j%20desktop&utm_adgroup=download&gad_source=1&gad_campaignid=20973570619&gbraid=0AAAAADk9OYo5tpsYzh7zktWLjBAkMdG_G&gclid=CjwKCAjwtp7VBhBjEiwAJfpV-5wVB5Zjop6biY1jOgQxDG1Zp9C4SDJ_6tJJhLjavqRB_5DOQJLDUxoC8cUQAvD_BwE)


---

## 2. Create a Project

In Neo4j Desktop:

1. Create a new instance
2. Give the instance a name
3. Set a password

---


## 4. Start the Database

Select the instance and click:

```text
Start
```

Wait until the database shows that it is running.

---

## 5. Open the Neo4j Query Tool

Click on `Connected` and choose the query

---

## 6. Add data to Import folder

Click `Open folder` and navigate to the import folder. Drop all the csv files created by build_dataset.py into the folder.

---

## 7. Load data and start querying!

Follow along with the notes.md file.

---


# Option 2: Neo4j AuraDB

Neo4j AuraDB is the cloud-hosted option. It does not require a local Neo4j database.

## 1. Create a Neo4j Account

Create or sign into a Neo4j account.

Open the Neo4j Aura console.

---

## 2. Create an AuraDB Instance

From the Aura console:

1. Select **Create instance**.
2. Select **AuraDB**.
3. Choose the desired database tier.
4. Give the instance a name.
5. Create the instance.

AuraDB will provide the database credentials.

**Save the generated password!**

---

## 3. Start/Access the Instance

Open the newly created AuraDB instance.

Connect to the instance.

Open the Query interface.

---

## 4. Get the AuraDB Connection URI

Open the connection information for the AuraDB instance.

The URI will look similar to:

```text
neo4j+s://xxxxxxxx.databases.neo4j.io
```

Copy the URI provided by AuraDB.

Use the password generated when the instance was created.

---

# Connecting Python to Neo4j

The project uses the official Neo4j Python Driver to connect Python to the database.

## 1. Install the Driver

The driver is included in `requirements.txt`:

```text
neo4j
```

Install it with:

```bash
pip install -r requirements.txt
```

Verify that it is installed:

```bash
pip show neo4j
```

---

## 2. Test a Local Neo4j Desktop Connection

For Neo4j Desktop, create a Python file such as:

```text
test_connection.py
```

Use:

```python
from neo4j import GraphDatabase

URI = "YOUR URI"
USERNAME = "USERNAME HERE"
PASSWORD = "PASSWORD HERE"

driver = GraphDatabase.driver(
    URI,
    auth=(USERNAME, PASSWORD)
)

try:
    driver.verify_connectivity()
    print("Neo4j Desktop connection successful.")
finally:
    driver.close()
```

Run:

```bash
python test_connection.py
```

Expected output:

```text
Neo4j Desktop connection successful.
```


---



# Basic Python Query

Once the connection is working, Python can execute Cypher queries.

```python
from neo4j import GraphDatabase

driver = GraphDatabase.driver(
    URI,
    auth=(USERNAME, PASSWORD)
)

with driver.session() as session:
    result = session.run(
        "RETURN 'Hello from Python!' AS message"
    )

    for record in result:
        print(record["message"])

driver.close()
```

Expected output:

```text
Hello from Python!
```

---

# Troubleshooting

## `ModuleNotFoundError: No module named 'neo4j'`

Make sure the virtual environment is active and install the requirements:

```bash
pip install -r requirements.txt
```

Then verify:

```bash
pip show neo4j
```

---

## Python Cannot Connect to Neo4j Desktop

Check that:

1. Neo4j Desktop is open.
2. The local database is running.
3. The URI is correct.
4. The username is `neo4j`.
5. The password is correct.

Try:

```text
neo4j://localhost
```

or:

```text
bolt://localhost:7687
```

---

## Python Cannot Connect to AuraDB

Check that:

1. The AuraDB instance is running.
2. The URI was copied correctly.
3. The username is correct.
4. The password is correct.
5. The computer has an internet connection.
6. The Python environment has the `neo4j` package installed.

The AuraDB URI should normally begin with:

```text
neo4j+s://
```

---