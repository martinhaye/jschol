// ##### Unit Page ##### //
// this.props = {
//   unit: {id: , name: , type: , status }}
//   header: {breadcrumb: [], campusID: , campusName: , campuses: [], logo: , nav_bar: [], social: }
//   content: { page content },
//   marquee: {about: , carousel: , extent: }
//   sidebar: []
// }

import React from 'react'
import { Link } from 'react-router-dom'

import Contexts from '../contexts.jsx'
import PageBase from './PageBase.jsx'
import Header1Comp from '../components/Header1Comp.jsx'
import Header2Comp from '../components/Header2Comp.jsx'
import SubheaderComp from '../components/SubheaderComp.jsx'
import NavBarComp from '../components/NavBarComp.jsx'
import BreadcrumbComp from '../components/BreadcrumbComp.jsx'
import CampusLayout from '../layouts/CampusLayout.jsx'
import DepartmentLayout from '../layouts/DepartmentLayout.jsx'
import SeriesLayout from '../layouts/SeriesLayout.jsx'
import JournalLayout from '../layouts/JournalLayout.jsx'
import UnitSearchLayout from '../layouts/UnitSearchLayout.jsx'
import UnitStaticPageLayout from '../layouts/UnitStaticPageLayout.jsx'
import SidebarComp from '../components/SidebarComp.jsx'
import MetaTagsComp from '../components/MetaTagsComp.jsx'
import ServerErrorComp from '../components/ServerErrorComp.jsx'

class UnitPage extends PageBase {
  // PageBase will fetch the following URL for us, and place the results in this.state.pageData
  // will likely at some point want to move these (search, home, pages) to different extensions of PageBase,
  // as all kinds of CMS-y stuff will live here, though perhaps not, to capitalize on React's
  // diff-ing of pages - all these different pages have quite a few of the same components:
  // header, footer, nav, sidebar. 
  
  // Unit ID for permissions checking
  pagePermissionsUnit() {
    return this.props.match.params.unitID
  }

  cmsPage = (data, cms, elementName) => {
    const PageEl = cms.modules[elementName]
    if ((this.state.adminLogin && !this.state.fetchingPerms && !this.state.isEditingPage) ||
        !this.state.adminLogin)
    {
      console.log("Editing turned off; redirecting to unit page.")
      setTimeout(()=>this.props.history.push(data.unit.id == "root" ? "/" : `/uc/${data.unit.id}`), 0)
    }
    else if (!PageEl)
      return <ServerErrorComp error="Not Found"/>
    else
      return <PageEl unit={data.unit} data={data.content} sendApiData={this.sendApiData} sendBinaryFileData={this.sendBinaryFileData}/>
  }

  renderData(data) { 
    const sidebar = <SidebarComp data={data.sidebar}/>
    const pageName = this.props.match.params.pageName
    const unitType = data.unit.type
    const isCmsPage = /^(profile|carousel|issueConfig|userConfig|unitBuilder|nav|sidebar|redirects|authorSearch|pubFieldList|pubField)$/.test(pageName)
    return (
      <Contexts.CMS.Consumer>
        { (cms) =>
          <div>
            { !isCmsPage && <MetaTagsComp title={data.content.title || data.unit.name}/> }
            { unitType == "root"
              ? <Header1Comp/>
              : <Header2Comp type={unitType} unitID={data.unit.id} />
            }
            { unitType != "root" && <SubheaderComp unit={data.unit} header={data.header} /> }
            <NavBarComp
              navBar={data.header.nav_bar} unit={data.unit} socialProps={data.header.social} />
            <BreadcrumbComp array={data.header.breadcrumb} />
            { this.extGA(data.unit.id) /* Google Analytics for external trackers called from PageBase */ }
            { this.state.fetchingData ?
                <h2 style={{ marginTop: "5em", marginBottom: "5em" }}>Loading...</h2>
              : pageName === 'search' ?
                <SeriesLayout unit={data.unit} data={data.content} sidebar={sidebar} marquee={data.marquee}/>
              : isCmsPage ?
                <cms.modules.UnitCMSLayout pageName={pageName} data={data} location={this.props.location}
                                           sendApiData={this.sendApiData} sendBinaryFileData={this.sendBinaryFileData}/>
              : pageName && !(data.content.issue) ?
                /* If there's issue data here it's a journal page, otherwise it's static content */
                <UnitStaticPageLayout unit={data.unit} data={data.content} sidebar={sidebar} fetchPageData={this.fetchPageData}/>
              : unitType === 'oru' ?
                <DepartmentLayout unit={data.unit} data={data.content} sidebar={sidebar} marquee={data.marquee}/>
              : unitType == 'campus' ?
                <CampusLayout unit={data.unit} data={data.content} sidebar={sidebar}/>
              : unitType.includes('series') ?
                <SeriesLayout unit={data.unit} data={data.content} sidebar={sidebar} marquee={data.marquee}/>
              : unitType === 'journal' ?
                <JournalLayout unit={data.unit} data={data.content} sidebar={sidebar} marquee={data.marquee}/>
              : <ServerErrorComp error="Not Found"/>
            }
          </div>
        }
      </Contexts.CMS.Consumer>
    )
  }

}

export default UnitPage
