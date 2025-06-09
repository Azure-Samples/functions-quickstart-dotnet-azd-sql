"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.httpTriggerSqlOutput = httpTriggerSqlOutput;
async function httpTriggerSqlOutput(request, context) {
    context.log('HTTP trigger with SQL Output Binding function processed a request.');
    try {
        // Parse the request body as ToDoItem
        const toDoItem = await request.json();
        if (!toDoItem || !toDoItem.title || !toDoItem.url) {
            return {
                status: 400,
                jsonBody: {
                    error: 'Missing required fields: title and url are required'
                }
            };
        }
        // Set SQL output binding via context.extraOutputs
        context.extraOutputs.set('todoItems', toDoItem);
        return {
            status: 200,
            jsonBody: toDoItem
        };
    }
    catch (error) {
        context.log('Error processing request:', error);
        return {
            status: 400,
            jsonBody: {
                error: 'Invalid request body. Expected ToDoItem JSON.'
            }
        };
    }
}
//# sourceMappingURL=httpTriggerSqlOutput.js.map