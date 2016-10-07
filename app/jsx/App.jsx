
// ##### Top-level React Router App ##### //

import React from 'react'
import ReactDOM from 'react-dom'
import { Router, Route, IndexRoute, Link, browserHistory } from 'react-router'

import HomePage from './pages/HomePage.jsx'
import UnitPage from './pages/UnitPage.jsx';
import ItemPage from './pages/ItemPage.jsx';
import SearchPage from './pages/SearchPage.jsx';

class App extends React.Component {
  render = ()=>
    <div>
      {this.props.children}
    </div>
}

const routes = (
  <Route path="/" component={App}>
    <IndexRoute component={HomePage} />
    <Route path="/unit/:unitID" component={UnitPage} />
    <Route path="/item/:itemID" component={ItemPage} />
    <Route path="/search" component={SearchPage} />
  </Route>
)

// When running in the browser, render with React (vs. server-side where iso runs it for us)
if (!(typeof document === "undefined")) {
  ReactDOM.render((
    <Router history={browserHistory}>
      {routes}
    </Router>
  ), document.getElementById('main'))
}

module.exports = routes