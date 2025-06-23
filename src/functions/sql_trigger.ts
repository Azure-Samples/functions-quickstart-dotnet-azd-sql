import { app, InvocationContext } from '@azure/functions';
import { SqlChange } from '@azure/functions';
import { ToDoItem } from '../models/ToDoItem';

// SQL trigger
app.sql('sqlTriggerToDo', {
    tableName: 'dbo.ToDo',
    connectionStringSetting: 'AZURE_SQL_CONNECTION_STRING_KEY',
    handler: async (changes: SqlChange[], context: InvocationContext): Promise<void> => {
        context.log('SQL trigger function processed a request.');
        
        for (const change of changes) {
            const toDoItem: ToDoItem = change.Item as ToDoItem;
            context.log(`Change operation: ${change.Operation}`);
            context.log(`Id: ${toDoItem.id}, Title: ${toDoItem.title}, Url: ${toDoItem.url}, Completed: ${toDoItem.completed}`);
        }
    }
});
