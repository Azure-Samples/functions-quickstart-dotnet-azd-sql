"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sqlTriggerToDo = sqlTriggerToDo;
async function sqlTriggerToDo(changes, context) {
    context.log('SQL trigger function processed a request.');
    for (const change of changes) {
        const toDoItem = change.Item;
        context.log(`Change operation: ${change.Operation}`);
        context.log(`Id: ${toDoItem.id}, Title: ${toDoItem.title}, Url: ${toDoItem.url}, Completed: ${toDoItem.completed}`);
    }
}
//# sourceMappingURL=sqlTriggerToDo.js.map