
import React from 'react'
import { Link } from 'react-router'

import PageBase from './PageBase.jsx'
import HeaderComp from '../components/HeaderComp.jsx'
import NavComp from '../components/NavComp.jsx'
import BreadcrumbComp from '../components/BreadcrumbComp.jsx'
import SidebarNavComp from '../components/SidebarNavComp.jsx'

class StaticPage extends PageBase
{
  // PageBase will fetch the following URL for us, and place the results in this.state.pageData
  pageDataURL(props) {
    return "/api/static/" + props.params.unitID + "/" + props.params.pageName
  }

  // OK to display the Edit Page button if user is logged in
  hasEditableComponents() {
    return true
  }

  // PageBase calls this when the API data has been returned to us
  renderData(data) { return(
    <div className="l-about">
      <HeaderComp admin={this.state.admin} />
      <NavComp />
      <BreadcrumbComp array={data.breadcrumb} />
      <div className="c-columns">
        <aside>
          <section className="o-columnbox2 c-sidebarnav">
            <header>
              <h1 className="o-columnbox2__heading">{data.page.title}</h1>
            </header>
            <SidebarNavComp links={data.sidebarNavLinks}/>
          </section>
        </aside>
        <main>
          <Editable admin={this.state.admin}>
            <StaticContent {...data.page}/>
          </Editable>
        </main>
        <aside>
          <section className="o-columnbox2 c-sidebarnav">
            <header>
              <h1 className="o-columnbox2__heading">Featured Articles</h1>
            </header>
            <nav className="c-sidebarnav">
              Lorem ipsum
            </nav>
          </section>
          <section className="o-columnbox2 c-sidebarnav">
            <header>
              <h1 className="o-columnbox2__heading">New Journal Issues</h1>
            </header>
            <nav className="c-sidebarnav">
              Lorem ipsum
            </nav>
          </section>
        </aside>
      </div>
    </div>
  )}
}

class Editable extends React.Component
{
  render() { 
    let p = this.props; 
    if (!p.admin || !p.admin.editingPage)
      return p.children
    return (
      <div style={{position: "relative"}}>
        { p.children }
        <button style={{position: "absolute", right: "1em", bottom: "1em"}}>Edit</button>
      </div>
    )
  }
}

class StaticContent extends React.Component
{
  render() { return(
    <section className="o-columnbox1">
      <header>
        <h1 className="o-columnbox1__heading">{this.props.title}</h1>
      </header>
      <div dangerouslySetInnerHTML={{__html: this.props.html}}/>
    </section>
  )}
}

module.exports = StaticPage;