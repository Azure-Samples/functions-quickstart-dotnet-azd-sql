import { HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { ToDoItem } from '../models/ToDoItem';

export async function httpTriggerSqlOutput(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
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

        // Set SQL output binding via context.extraOutputs
        context.extraOutputs.set('todoItems', toDoItem);

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