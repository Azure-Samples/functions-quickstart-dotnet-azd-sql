export interface ToDoItem {
    id: string;
    order?: number;
    title: string;
    url: string;
    completed?: boolean;
}