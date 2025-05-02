import { html, LitElement } from "lit";
import FieldRenderer from "./field_renderer";

export default class RelationField extends LitElement {
	static properties = {
		name: {},
		fields: {},
		defaultValue: {},
		required: {},
		mode: {},
	};

	createRenderRoot() {
		return this;
	}

	render() {
		return html`
      <div class="flex flex-col gap-2">
        <p>${this.name}</p>
        <div class="px-4 py-2 border border-gray-400 rounded">
          ${this.fields.map((field) => FieldRenderer.renderField(field, "relation"))}
        </div>
      </div>
    `;
	}
}
