import { Component } from '@angular/core';
import { Greeting } from './greeting/greeting';
import { SiteFooter } from './site-footer/site-footer';

@Component({
  selector: 'app-root',
  imports: [Greeting, SiteFooter],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = 'Tasks First';
}
