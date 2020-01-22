import React from 'react'
import { Link } from 'react-router-dom'
import FormComp from '../components/FormComp.jsx'
import _ from 'lodash'
import Contexts from '../contexts.jsx'
import MetaTagsComp from '../components/MetaTagsComp.jsx'
import ModalComp from '../components/ModalComp.jsx'
import WysiwygEditorComp from '../components/WysiwygEditorComp.jsx'

export default class FieldListLayout extends React.Component
{
  state = { editingRow: null,
            anyChanges: false }

  handleSubmit = (event, data) => {
    event.preventDefault()
    this.props.sendApiData("PUT", event.target.action, {data: data})
  }

  editForm = () =>
    <FormComp to={`/api/unit/${this.props.unit.id}/pubFields/${this.state.editingRow.id}`}
              onSubmit={(event, data) => this.handleSubmit(event, data)}>

      <label className="c-editable-page__label" htmlFor="id">Field ID: </label>
      <input type="text" name="id" disabled={true} id="id" defaultValue={this.state.editingRow.id} />

      <br/><br/>
      <label className="c-editable-page__label" htmlFor="format">Format: </label>
      <select name="format" id="o-input__droplist-label2" onChange={this.props.changeType} value={this.state.editingRow.format}>
        { _.map(this.props.data.formats, row =>
            <option key={row.id} value={row.id}>{row.id}: {row.descrip}</option>)
        }
      </select>

      <br/><br/>
      <label className="c-editable-page__label" htmlFor="name">Name: </label>
      <input type="text" name="name" id="name" defaultValue={this.state.editingRow.attrs.name} />

      <br/><br/>
      <label className="c-editable-page__label" htmlFor="placeholder">Placeholder (displayed inside input element): </label>
      <input type="text" name="placeholder" id="placeholder" defaultValue={this.state.editingRow.attrs.placeholder} />

      <br/><br/>
      <label className="c-editable-page__label" htmlFor="descrip">Description (shown in sidebar next to input): </label>
      <WysiwygEditorComp className="c-editable-page__input" name="descrip" id="descrip"
          html={this.state.editingRow.attrs.descrip} unit={this.props.unit.id}
          onChange={ newText => {
            let newRow = _.clone(this.state.editingRow)
            newRow.attrs.descrip = newText
            this.setState({editingRow: newRow})
          } }
          buttons={[
                    ['strong', 'em', 'underline', 'link', 'superscript', 'subscript'],
                   ]} />

    </FormComp>

  render = () =>
    <div>
      <MetaTagsComp title="Metadata Fields"/>
      <h3>Metadata Field: </h3>
      <div className="c-columns">
        <main>
          <section className="o-columnbox1">

          </section>
        </main>
      </div>
    </div>
}
