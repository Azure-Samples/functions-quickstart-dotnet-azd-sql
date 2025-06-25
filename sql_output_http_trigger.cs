using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Extensions.Sql;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using FromBodyAttribute = Microsoft.Azure.Functions.Worker.Http.FromBodyAttribute;

namespace AzureSQL.ToDo;

public class SqlOutputBindingHttpTriggerCSharp
{
    private readonly ILogger _logger;

    public SqlOutputBindingHttpTriggerCSharp(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<SqlOutputBindingHttpTriggerCSharp>();
    }

    // Visit https://aka.ms/sqlbindingsoutput to learn how to use this output binding
    [Function("httptrigger-sql-output")]
    public async Task<OutputType> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequestData req,
        [FromBody] ToDoItem toDoItem
    )
    {
        _logger.LogInformation(
            "C# HTTP trigger with SQL Output Binding function processed a request."
        );

        return new OutputType
        {
            ToDoItem = toDoItem,
            HttpResponse = new CreatedResult
            (
                req.Url,
                toDoItem
            )
        };
    }
}

public class OutputType
{
    [SqlOutput("dbo.ToDo", connectionStringSetting: "AZURE_SQL_CONNECTION_STRING_KEY")]
    public required ToDoItem ToDoItem { get; set; }

    //[HttpResponse]
    public required IActionResult HttpResponse { get; set; }
}
