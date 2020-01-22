import React from 'react'
import { Link } from 'react-router-dom'
import FormComp from '../components/FormComp.jsx'
import _ from 'lodash'
import Contexts from '../contexts.jsx'
import MetaTagsComp from '../components/MetaTagsComp.jsx'

export default class FieldListLayout extends React.Component
{
  render = () =>
    <div>
      <MetaTagsComp title="Metadata Fields"/>
      <h3>Metadata Fields Configuration</h3>
      <div className="c-columns">
        <main>
          <section className="o-columnbox1">
            <div className="c-datatable-nomaxheight">
              <table>
                <thead>
                  <tr>
                    <th scope="col">Field</th>
                    <th scope="col">Name</th>
                    <th scope="col">Format</th>
                    <th scope="col">Always required?</th>
                  </tr>
                </thead>
                <tbody>
                  { _.map(this.props.data.fields, row =>
                    <tr key={row.id}>
                      <td className="c-editable-tableCell">
                        <a href={`/uc/${this.props.unit.id}/field/${row.id}`}>{row.id}</a>
                      </td>
                      <td className="c-editable-tableCell">
                        {row.attrs.name}
                      </td>
                      <td className="c-editable-tableCell">
                        {row.format}
                      </td>
                      <td className="c-editable-tableCell">
                        {row.attrs.is_always_required ? "yes" : null}
                      </td>
                    </tr>)
                  }
                </tbody>
              </table>
              <button>Add new field</button>
            </div>
          </section>
        </main>
      </div>
    </div>
}
