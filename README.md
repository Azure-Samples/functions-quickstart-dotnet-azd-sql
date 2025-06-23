# Azure Functions with SQL Triggers and Bindings (TypeScript)

An Azure Functions QuickStart project that demonstrates how to use both SQL Triggers and SQL Output Bindings with the Azure Developer CLI (azd) for rapid, event-driven integration with Azure SQL Database.

## Architecture

![Azure Functions SQL Output Binding Architecture](./diagrams/architecture.png)

This architecture shows how Azure Functions can both write to and react to changes in an Azure SQL Database using output bindings and triggers. The key components include:

- **Client Applications**: Send HTTP requests to the Azure Function
- **Azure Function with SQL Output Binding**: Receives HTTP requests and writes data to SQL Database
- **Azure Function with SQL Trigger**: Reacts to changes in SQL Database tables
- **Azure SQL Database**: Stores ToDo items
- **Azure Monitor**: Provides logging and metrics for the function execution

This serverless architecture enables scalable, event-driven data ingestion and processing with minimal code.

## Top Use Cases

### SQL Output Binding
1. Data Ingestion API: Quickly create APIs that write data to SQL Database without custom data access code.
2. Serverless CRUD Operations: Build serverless endpoints for line-of-business apps that interact with SQL data.

### SQL Trigger
1. Change Data Capture & Auditing: Automatically react to inserts, updates, or deletes in your SQL tables for auditing, notifications, or downstream processing.
2. Event-Driven Workflows: Trigger business logic or integration with other services when data changes in SQL, such as updating caches, sending alerts, or synchronizing systems.

## Features

- SQL Output Binding
- SQL Trigger
- TypeScript v4 programming model with Node.js 22.x
- Azure Functions Flex Consumption plan
- Azure Developer CLI (azd) integration for easy deployment
- Infrastructure as Code using Bicep templates

## Getting Started

### Prerequisites

- [Node.js 22.x](https://nodejs.org/) or later
- [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local#install-the-azure-functions-core-tools)
- [Azure Developer CLI (azd)](https://docs.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- An Azure subscription

### Quickstart

1. Clone this repository
   ```bash
   git clone https://github.com/Azure-Samples/functions-quickstart-typescript-azd-sql.git
   cd functions-quickstart-typescript-azd-sql
   ```
2. Provision Azure resources using azd
   ```bash
   azd provision
   ```
   This will create all necessary Azure resources including:
   - Azure SQL Database (default name: ToDo)
   - Azure Function App
   - App Service Plan
   - Other supporting resources
   - local.settings.json for local development with Azure Functions Core Tools, which should look like this:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "node",
       "WEBSITE_SITE_NAME": "ToDo-local",
       "AZURE_SQL_CONNECTION_STRING_KEY": "Server=tcp:<server>.database.windows.net,1433;Database=ToDo;Authentication=Active Directory Default; TrustServerCertificate=True; Encrypt=True;"
     }
   }
   ```
   The `azd` command automatically sets up the required connection strings and application settings.
3. Start the function locally
   ```bash
   npm install
   npm run build
   func start
   ```
   Or use VS Code to run the project with the built-in Azure Functions extension by pressing F5.
4. Test the function locally by sending a POST request to the HTTP endpoint:
   ```json
   {
     "id": "b1a7c1e2-1234-4f56-9abc-1234567890ab",
     "order": 1,
     "title": "Example: Walk the dog",
     "url": "https://example.com/todo/1",
     "completed": false
   }
   ```
   You can use tools like curl, Postman, or httpie:
   ```bash
   curl -X POST http://localhost:7071/api/httpTriggerSqlOutput \
     -H "Content-Type: application/json" \
     -d '{"id":"b1a7c1e2-1234-4f56-9abc-1234567890ab","order":1,"title":"Example: Walk the dog","url":"https://example.com/todo/1","completed":false}'
   ```
   The function will write the item to the SQL database and return the created object.
5. Deploy to Azure
   ```bash
   azd up
   ```
   This will build your function app and deploy it to Azure. The deployment process:
   - Checks for any bicep changes using `azd provision`
   - Builds the TypeScript project using `azd package`
   - Publishes the function app using `azd deploy`
   - Updates application settings in Azure
6. Test the deployed function by sending a POST request to the Azure Function endpoint (see Azure Portal for the URL).

## Understanding the Functions

### SQL Output Binding Function ([src/functions/sql_output_http_trigger.ts](src/functions/sql_output_http_trigger.ts))
This function receives HTTP POST requests and writes the payload to the SQL database using the SQL output binding. The key environment variable is:
- `AZURE_SQL_CONNECTION_STRING_KEY`: The identity-based connection string for the Azure SQL Database loaded from app settings or env vars

```typescript
import { app, HttpRequest, HttpResponseInit, InvocationContext, output } from '@azure/functions';
import { ToDoItem } from '../models/ToDoItem';

const sqlOutput = output.sql({
    commandText: 'dbo.ToDo',
    connectionStringSetting: 'AZURE_SQL_CONNECTION_STRING_KEY'
});

app.http('httpTriggerSqlOutput', {
    methods: ['POST'],
    authLevel: 'function',
    extraOutputs: [sqlOutput],
    handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
        const toDoItem: ToDoItem = await request.json() as ToDoItem;
        context.extraOutputs.set(sqlOutput, toDoItem);
        return {
            status: 200,
            jsonBody: toDoItem
        };
    }
});
```
- Accepts a JSON body matching the `ToDoItem` class (see below).
- Writes the item to the `[dbo].[ToDo]` table in SQL.
- Returns the created object as the HTTP response.

### SQL Trigger Function ([src/functions/sql_trigger.ts](src/functions/sql_trigger.ts))
This function responds to changes in the SQL database. It enables event-driven processing whenever rows in the `[dbo].[ToDo]` table are inserted, updated, or deleted.

```typescript
import { app, InvocationContext } from '@azure/functions';
import { SqlChange } from '@azure/functions';
import { ToDoItem } from '../models/ToDoItem';

app.sql('sqlTriggerToDo', {
    tableName: 'dbo.ToDo',
    connectionStringSetting: 'AZURE_SQL_CONNECTION_STRING_KEY',
    handler: async (changes: SqlChange[], context: InvocationContext): Promise<void> => {
        for (const change of changes) {
            const toDoItem: ToDoItem = change.Item as ToDoItem;
            context.log(`Change operation: ${change.Operation}`);
            context.log(`Id: ${toDoItem.id}, Title: ${toDoItem.title}, Url: ${toDoItem.url}, Completed: ${toDoItem.completed}`);
        }
    }
});
```
- Monitors the `[dbo].[ToDo]` table for changes.
- Logs the operation type and details of each changed item.

### ToDoItem Model ([src/models/ToDoItem.ts](src/models/ToDoItem.ts))
```typescript
export interface ToDoItem {
  id: string;
  order?: number;
  title: string;
  url: string;
  completed?: boolean;
}
```
- The JSON property `id` maps to the TypeScript property `id`.
- All other properties map directly by name and type.

## Monitoring and Logs

You can monitor your function in the Azure Portal:

1. Navigate to your function app in the Azure Portal
2. Select "Functions" from the left menu
3. Click on your function (httpTriggerSqlOutput or sqlTriggerToDo)
4. Select "Monitor" to view execution logs

### Application Insights: Traces and Transactions

For deeper monitoring and diagnostics, use Application Insights:

- **Traces**: Go to your Application Insights resource in the Azure Portal, select "Logs" and run queries against the `traces` table to view detailed logs, custom messages, and errors generated by your functions.
- **Transactions (End-to-End Transaction Diagnostics)**: In Application Insights, use the "Transaction Search" or "Application Map" features to trace the flow of a single request or operation across your function app and related Azure resources. This helps you diagnose performance issues, bottlenecks, and failures in distributed workflows.

**Example Kusto Query for Traces:**
```kusto
traces
| where operation_Name == "httpTriggerSqlOutput" or operation_Name == "sqlTriggerToDo"
| order by timestamp desc
```

**Example: Viewing a Transaction**
- In Application Insights, open "Transaction Search" and filter by operation name or time range to see all related logs, dependencies, and performance data for a single invocation.

Use the "Live Metrics" feature to see real-time information when testing.

## SQL Trigger Testing

1. Make a change to the `[dbo].[ToDo]` table in your Azure SQL Database (insert, update, or delete a row).
2. The `sqlTriggerToDo` function will automatically execute and log the change.
3. You can view the logs locally in your terminal or in the Azure Portal under your Function App's "Monitor" tab.

Example Log Output:
```
Change operation: Insert
Id: b1a7c1e2-1234-4f56-9abc-1234567890ab, Title: Example: Walk the dog, Url: https://example.com/todo/1, Completed: False
```

This enables you to build reactive, event-driven workflows based on changes in your SQL data.

## Resources

- [Azure Functions SQL Bindings & Triggers Documentation (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-azure-sql?tabs=isolated-process%2Cextensionv4&pivots=programming-language-javascript)
- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/azure-sql/)
- [Azure Developer CLI Documentation](https://docs.microsoft.com/azure/developer/azure-developer-cli/install-azd/)
- [TypeScript Azure Functions Programming Model v4](https://docs.microsoft.com/azure/azure-functions/functions-reference-node)