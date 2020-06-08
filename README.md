# Overview 
This repository is to demostrate how to use the Cosmos SDK to get storage statistics for a database/collection

# Getting Started
## Console App
1. git clone https://github.com/briandenicola/cosmosdb-partition-monitor
2. cd ConsoleApp
3. dotnet restore
4. dotnet build 
5. dotnet run --account (https://docdb.documents.azure.com) --masterKey (DocumentDB master key) --database (DocumentDB database ID) --collection (DocumentDB collection ID)

## Monitor
TBD

## To Do
- [ ] Logic App to send Alert to MS Teams
- [ ] Funtion App that runs on schedule to query a Database/Collection and send alert to Logic App
- [ ] Expand to multiple database/collections 
- [ ] Alert suppression 