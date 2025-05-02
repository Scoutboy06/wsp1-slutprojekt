import { LitElement, html } from "lit";
import FieldRenderer from "./field_renderer";

export default class ArrayField extends LitElement {
	static properties = {
		name: {},
		fields: {},
		defaultValue: {},
		items: { state: true },
		required: {},
		mode: {},
	};

	createRenderRoot() {
		return this;
	}

	willUpdate(changedProps) {
		if (changedProps.has("defaultValue")) {
			this.items = this.defaultValue;
		}
	}

	createNewItem() {
		console.log("fields", this.fields);
		console.log("defaultValue", this.defaultValue);
		console.log("items", this.items);
		const newItem = {};
		for (const field of this.fields) {
			newItem[field.name] = {};
		}
		this.items = [...this.items, newItem];
	}

	render() {
		return html`
      <div class="flex flex-col gap-2">
        <p>${this.name}</p>
        <div class="flex flex-col gap-4 px-4 py-4 border border-gray-400 rounded">
          ${this.items.map(
						(item) => html`
							<div class="p-4 border border-gray-400 rounded">
								${this.fields.map((field) => {
									const data = item[field.name];
									for (const rField of field.relation_field) {
										rField.default = data[rField.name];
									}
									console.log({ item, field, data });

									return FieldRenderer.renderField(field, this.mode);
								})}
							</div>
          	`,
					)}

					<button
						type="button"
						class="flex px-3 py-2 pr-1 w-min border border-gray-600 rounded cursor-pointer transition-colors"
						@click=${this.createNewItem}
					>
						<span class="text-nowrap">New item</span>
						<i class="icon">add</i>
					</button>
        </div>
      </div>
    `;
	}
}
