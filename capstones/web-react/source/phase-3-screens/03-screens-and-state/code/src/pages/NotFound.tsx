import { Page } from '../shared/Page';
import { Link } from 'react-router';
export function Component() {
  return <Page title="Not found"><p>This page is not available.</p><Link to="/">Home</Link></Page>;
}
