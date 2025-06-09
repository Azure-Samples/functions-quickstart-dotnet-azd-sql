import { InvocationContext } from '@azure/functions';
import { ToDoItem } from '../models/ToDoItem';

export async function sqlTriggerToDo(changes: any[], context: InvocationContext): Promise<void> {
    context.log('SQL trigger function processed a request.');
    
    for (const change of changes) {
        const toDoItem: ToDoItem = change.Item;
        context.log(`Change operation: ${change.Operation}`);
        context.log(`Id: ${toDoItem.id}, Title: ${toDoItem.title}, Url: ${toDoItem.url}, Completed: ${toDoItem.completed}`);
    }
}