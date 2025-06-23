import { app, HttpRequest, HttpResponseInit, InvocationContext, output } from '@azure/functions';
import { ToDoItem } from '../models/ToDoItem';

// SQL output binding
const sqlOutput = output.sql({
    commandText: 'dbo.ToDo',
    connectionStringSetting: 'AZURE_SQL_CONNECTION_STRING_KEY'
});

// HTTP trigger with SQL output binding
app.http('httpTriggerSqlOutput', {
    methods: ['POST'],
    authLevel: 'function',
    extraOutputs: [sqlOutput],
    handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
        context.log('HTTP trigger with SQL Output Binding function processed a request.');

        try {
            // Parse the request body as ToDoItem
            const toDoItem: ToDoItem = await request.json() as ToDoItem;
            
            if (!toDoItem || !toDoItem.title || !toDoItem.url) {
                return {
                    status: 400,
                    jsonBody: { 
                        error: 'Missing required fields: title and url are required'
                    }
                };
            }

            // Set SQL output binding
            context.extraOutputs.set(sqlOutput, toDoItem);

            return {
                status: 200,
                jsonBody: toDoItem
            };
        } catch (error) {
            context.log('Error processing request:', error);
            return {
                status: 400,
                jsonBody: { 
                    error: 'Invalid request body. Expected ToDoItem JSON.'
                }
            };
        }
    }
});
