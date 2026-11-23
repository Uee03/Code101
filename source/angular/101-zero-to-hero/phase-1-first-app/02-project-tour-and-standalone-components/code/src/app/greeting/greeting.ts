import { Component } from '@angular/core';

@Component({
  selector: 'app-greeting',
  templateUrl: './greeting.html',
  styleUrl: './greeting.css'
})
export class Greeting {
  protected readonly message = 'Welcome to your task list.';
}
