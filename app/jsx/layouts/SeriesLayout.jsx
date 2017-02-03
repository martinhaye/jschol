import React from 'react'
import { Link } from 'react-router'

import MarqueeComp from '../components/MarqueeComp.jsx'
import { ScholarlyWorks, SortComp, PaginationComp } from '../pages/SearchPage.jsx'

class SeriesLayout extends React.Component {
  render() {
    var data = this.props.data;
    return (
      <div className="c-columns">
        <main>
          <section className="o-columnbox1">
            <h4>Other series in this department: </h4>
            <ul>
              { data.content.series.map((s) => 
                <li key={s.unit_id}><Link to={"/unit/"+s.unit_id}>{s.name}</Link></li>)}
            </ul>
            <p>Some about text for the series.</p>
            <div className="l-search__sort-pagination">
              <SortComp query={data.content.query} />
              <input type="hidden" name="start" form="facetForm" value={data.content.query.start} />
              <PaginationComp query={data.content.query} count={data.content.count}/>
            </div>
            <ScholarlyWorks results={data.content.response} />

          </section>
        </main>
        <aside>
          <section className="o-columnbox2">
          </section>
        </aside>
      </div>
    )
  }
}

module.exports = SeriesLayout