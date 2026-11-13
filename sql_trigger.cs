using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Extensions.Sql;
using Microsoft.Extensions.Logging;

namespace AzureSQL.ToDo;

public static class ToDoTrigger
{
    [Function("sql_trigger_todo")]
    public static void Run(
        [SqlTrigger("[dbo].[ToDo]", "AZURE_SQL_CONNECTION_STRING_KEY")]
            IReadOnlyList<SqlChange<ToDoItem>> changes,
        FunctionContext context
    )
    {
        var logger = context.GetLogger("ToDoTrigger");
        foreach (SqlChange<ToDoItem> change in changes)
        {
            logger.LogInformation($"Change operation: {change.Operation}");
            
            // Handle different operation types
            switch (change.Operation)
            {
                case SqlChangeOperation.Insert:
                case SqlChangeOperation.Update:
                    // For INSERT and UPDATE operations, the Item contains the new/current values
                    var toDoItem = change.Item;
                    if (toDoItem != null)
                    {
                        logger.LogInformation(
                            $"Id: {toDoItem.Id}, Title: {toDoItem.title}, Url: {toDoItem.url}, Completed: {toDoItem.completed}"
                        );
                    }
                    else
                    {
                        logger.LogWarning($"{change.Operation} operation but item is null");
                    }
                    break;
                    
                case SqlChangeOperation.Delete:
                    // For DELETE operations, we need to check what data is available
                    // The Item might be null or have limited data since the row was deleted
                    if (change.Item != null)
                    {
                        logger.LogInformation($"Deleted item Id: {change.Item.Id}");
                        // Only log non-null properties for deletes
                        if (!string.IsNullOrEmpty(change.Item.title))
                            logger.LogInformation($"Deleted item Title: {change.Item.title}");
                        if (!string.IsNullOrEmpty(change.Item.url))
                            logger.LogInformation($"Deleted item Url: {change.Item.url}");
                        if (change.Item.completed.HasValue)
                            logger.LogInformation($"Deleted item Completed: {change.Item.completed}");
                    }
                    else
                    {
                        logger.LogInformation("Item was deleted but no item data is available");
                    }
                    break;
                    
                default:
                    logger.LogWarning($"Unknown operation type: {change.Operation}");
                    break;
            }
        }
    }
}
