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
                    <th scope="col">Field name</th>
                    <th scope="col">Action</th>
                  </tr>
                </thead>
                <tbody>
                  { _.map(this.props.data.fields, row => /* todo */
                    <tr key={row.id}>
                      <td className="c-editable-tableCell">
                        {row.id}
                      </td>
                      <td className="c-editable-tableCell">
                        <button onClick={e=>{ e.preventDefault(); this.setState({editingRow: row}) }}>View/Edit</button>
                      </td>
                    </tr>)
                  }
                  <tr key="new">
                    <td className="c-editable-tableCell">
                      <i>(add field)</i>
                    </td>
                    <td className="c-editable-tableCell">
                      Add button here
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </main>
      </div>
    </div>
}
