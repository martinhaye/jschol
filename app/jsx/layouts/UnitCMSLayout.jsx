import React from 'react'

import ServerErrorComp from '../components/ServerErrorComp.jsx'
import UnitProfileLayout from '../layouts/UnitProfileLayout.jsx'
import UnitCarouselConfigLayout from '../layouts/UnitCarouselConfigLayout.jsx'
import UnitIssueConfigLayout from '../layouts/UnitIssueConfigLayout.jsx'
import UnitUserConfigLayout from '../layouts/UnitUserConfigLayout.jsx'
import UnitSidebarConfigLayout from '../layouts/UnitSidebarConfigLayout.jsx'
import UnitNavConfigLayout from '../layouts/UnitNavConfigLayout.jsx'
import RedirectConfigLayout from '../layouts/RedirectConfigLayout.jsx'
import AuthorSearchLayout from '../layouts/AuthorSearchLayout.jsx'
import UnitBuilderLayout from '../layouts/UnitBuilderLayout.jsx'
import FieldListLayout from '../layouts/FieldListLayout.jsx'
import FieldLayout from '../layouts/FieldLayout.jsx'

class UnitCMSLayout extends React.Component {
  render () {
    let { pageName, data, location, sendApiData, sendBinaryFileData } = this.props
    console.log("props:", this.props)
    return (
      pageName === 'profile' ?
        <UnitProfileLayout unit={data.unit} data={data.content} sendApiData={sendApiData} sendBinaryFileData={sendBinaryFileData}/>
      : pageName === 'carousel' ?
        <UnitCarouselConfigLayout unit={data.unit} data={data.content} sendApiData={sendApiData} sendBinaryFileData={sendBinaryFileData}/>
      : pageName === 'issueConfig' ?
        <UnitIssueConfigLayout unit={data.unit} data={data.content} sendApiData={sendApiData}/>
      : pageName === 'userConfig' ?
        <UnitUserConfigLayout unit={data.unit} data={data.content} sendApiData={sendApiData}/>
      : pageName === 'unitBuilder' ?
        <UnitBuilderLayout unit={data.unit} data={data.content} sendApiData={sendApiData}/>
      : pageName === 'nav' ?
        <UnitNavConfigLayout unit={data.unit} data={data.content} sendApiData={sendApiData}/>
      : pageName === 'sidebar' ?
        <UnitSidebarConfigLayout unit={data.unit} data={data.content} sendApiData={sendApiData}/>
      : pageName === 'redirects' ?
        <RedirectConfigLayout data={data.content} sendApiData={sendApiData}/>
      : pageName === 'authorSearch' ?
        <AuthorSearchLayout data={data.content} location={location} sendApiData={sendApiData}/>
      : pageName === 'fields' ?
        <FieldListLayout unit={data.unit} data={data.content} sendApiData={sendApiData}/>
      : pageName === 'field' ?
        <FieldLayout unit={data.unit} data={data.content} sendApiData={sendApiData}/>
      : <ServerErrorComp error="Not Found"/>
    )
  }
}

export default UnitCMSLayout
