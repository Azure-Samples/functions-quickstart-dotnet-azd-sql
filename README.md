# Azure Functions with SQL Triggers and Bindings (C#)

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
1. **Data Ingestion API**: Quickly create APIs that write data to SQL Database without custom data access code.
2. **Serverless CRUD Operations**: Build serverless endpoints for line-of-business apps that interact with SQL data.

### SQL Trigger
1. **Change Data Capture & Auditing**: Automatically react to inserts, updates, or deletes in your SQL tables for auditing, notifications, or downstream processing.
2. **Event-Driven Workflows**: Trigger business logic or integration with other services when data changes in SQL, such as updating caches, sending alerts, or synchronizing systems.

## Features

* SQL Output Binding
* SQL Trigger
* Azure Functions Flex Consumption plan
* Azure Developer CLI (azd) integration for easy deployment
* Infrastructure as Code using Bicep templates

## Getting Started

### Prerequisites

- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) or later
- [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local#install-the-azure-functions-core-tools)
- [Azure Developer CLI (azd)](https://docs.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Azurite](https://github.com/Azure/Azurite) (for local Azure Storage emulation; can be run with `npx azurite`)
- An Azure subscription

### Quickstart

1. Clone this repository
   ```bash
   git clone https://github.com/Azure-Samples/functions-quickstart-dotnet-azd-sql.git
   cd functions-quickstart-dotnet-azd-sql
   ```

1. Provision Azure resources using azd
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
       "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
       "WEBSITE_SITE_NAME": "ToDo-local",
       "AZURE_SQL_CONNECTION_STRING_KEY": "Server=tcp:<server>.database.windows.net,1433;Database=ToDo;Authentication=Active Directory Default; TrustServerCertificate=True; Encrypt=True;"
     }
   }
   ```

   The `azd` command automatically sets up the required connection strings and application settings.

1. Start Azurite (local storage emulator)
   ```bash
   npx azurite --location ~/azurite-data
   ```

1. Start the function locally
   ```bash
   func start
   ```
   Or use VS Code to run the project with the built-in Azure Functions extension by pressing F5.

1. Test the function locally by sending a POST request to the HTTP endpoint:
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
   curl -X POST http://localhost:7071/api/httptrigger-sql-output \
     -H "Content-Type: application/json" \
     -d '{"id":"b1a7c1e2-1234-4f56-9abc-1234567890ab","order":1,"title":"Example: Walk the dog","url":"https://example.com/todo/1","completed":false}'
   ```
   The function will write the item to the SQL database and return the created object.

1. Deploy to Azure
   ```bash
   azd up
   ```
   This will build your function app and deploy it to Azure. The deployment process:
   - Checks for any bicep changes using `azd provision`
   - Builds the .NET project using `azd package`
   - Publishes the function app using `azd deploy`
   - Updates application settings in Azure

1. Test the deployed function by sending a POST request to the Azure Function endpoint (see Azure Portal for the URL).

## Understanding the Functions

### SQL Output Binding Function (`sql_output_http_trigger.cs`)

This function receives HTTP POST requests and writes the payload to the SQL database using the SQL output binding. The key environment variable is:

- `AZURE_SQL_CONNECTION_STRING_KEY`: The identity-based connection string for the Azure SQL Database loaded from app settings or env vars

**Source code:**
```csharp
[Function("httptrigger-sql-output")]
[SqlOutput("[dbo].[ToDo]", connectionStringSetting: "AZURE_SQL_CONNECTION_STRING_KEY")]
public async Task<ToDoItem> Run(
    [HttpTrigger(AuthorizationLevel.Function, "post", Route = "httptrigger-sql-output")] HttpRequestData req)
{
    var todoitem = await req.ReadFromJsonAsync<ToDoItem>() ?? new ToDoItem
    {
        Id = Guid.NewGuid(),
        order = 1,
        title = "Example: Walk the dog",
        url = "https://example.com/todo/1",
        completed = false
    };
    return todoitem;
}
```
- Accepts a JSON body matching the `ToDoItem` class (see below).
- Writes the item to the `[dbo].[ToDo]` table in SQL.
- Returns the created object as the HTTP response.

### SQL Trigger Function (`sql_trigger.cs`)

This function responds to changes in the SQL database. It enables event-driven processing whenever rows in the `[dbo].[ToDo]` table are inserted, updated, or deleted.

**Source code:**
```csharp
[Function("ToDoTrigger")]
public static void Run(
    [SqlTrigger("[dbo].[ToDo]", "AZURE_SQL_CONNECTION_STRING_KEY")] IReadOnlyList<SqlChange<ToDoItem>> changes,
    FunctionContext context)
{
    var logger = context.GetLogger("ToDoTrigger");
    foreach (SqlChange<ToDoItem> change in changes)
    {
        ToDoItem toDoItem = change.Item;
        logger.LogInformation($"Change operation: {change.Operation}");
        logger.LogInformation($"Id: {toDoItem.Id}, Title: {toDoItem.title}, Url: {toDoItem.url}, Completed: {toDoItem.completed}");
    }
}
```
- Monitors the `[dbo].[ToDo]` table for changes.
- Logs the operation type and details of each changed item.

### ToDoItem Model (`ToDoItem.cs`)

```csharp
public class ToDoItem
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }
    public int? order { get; set; }
    public required string title { get; set; }
    public required string url { get; set; }
    public bool? completed { get; set; }
}
```

- The JSON property `id` maps to the C# property `Id`.
- All other properties map directly by name and type.

## Monitoring and Logs

You can monitor your function in the Azure Portal:
1. Navigate to your function app in the Azure Portal
2. Select "Functions" from the left menu
3. Click on your function (SqlOutputBindingHttpTriggerCSharp1 or ToDoTrigger)
4. Select "Monitor" to view execution logs

Use the "Live Metrics" feature to see real-time information when testing.

## SQL Trigger Testing

1. Make a change to the `[dbo].[ToDo]` table in your Azure SQL Database (insert, update, or delete a row).
2. The `ToDoTrigger` function will automatically execute and log the change.
3. You can view the logs locally in your terminal or in the Azure Portal under your Function App's "Monitor" tab.

**Example Log Output:**
```
Change operation: Insert
Id: b1a7c1e2-1234-4f56-9abc-1234567890ab, Title: Example: Walk the dog, Url: https://example.com/todo/1, Completed: False
```

This enables you to build reactive, event-driven workflows based on changes in your SQL data.

## Resources

- [Azure Functions SQL Bindings & Triggers Documentation (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-azure-sql?tabs=isolated-process%2Cextensionv4&pivots=programming-language-csharp)
- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/azure-sql/)
- [Azure Developer CLI Documentation](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
