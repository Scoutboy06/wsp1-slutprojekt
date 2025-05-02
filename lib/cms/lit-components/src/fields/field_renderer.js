import { LitElement, html } from "lit";

export default class FieldRenderer extends LitElement {
	static properties = {
		"initial-data-name": {},
		"field-types-name": {},
		mode: {},
	};

	createRenderRoot() {
		return this;
	}

	/**
	 * @param {BaseFieldProps} field
	 * @param {any} initialValues
	 * @param {'create' | 'edit' | 'relation'} mode
	 */
	static renderField(field, value, mode) {
		switch (field.type) {
			case "string":
				return html`<string-field   .name=${field.name} .value=${value} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></string-field>`;
			case "boolean":
				return html`<boolean-field  .name=${field.name} .value=${value} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></boolean-field>`;
			case "email":
				return html`<email-field    .name=${field.name} .value=${value} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></email-field>`;
			case "password":
				return html`<password-field .name=${field.name} .value=${value} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></password-field>`;
			case "upload":
				return html`<upload-field   .name=${field.name} .value=${value} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></upload-field>`;
			case "array":
				return html`<array-field    .name=${field.name} .value=${value} .defaultValue=${field.default} .required=${field.required} .mode=${mode} .fields=${field.fields}></array-field>`;
			case "relation":
				return html`<relation-field .name=${field.name} .value=${value} .defaultValue=${field.default} .required=${field.required} .mode=${mode} .fields=${field.relation_field}></relation-field>`;
			default:
				return null;
		}
	}

	render() {
		const initialData = window[this["initial-data-name"]];
		const fieldTypes = window[this["field-types-name"]];
		const mode = this.mode;

		console.log("initialData", initialData);
		console.log("fieldTypes", fieldTypes);

		const initialValues = {};
		if (mode === "edit") {
			for (const field of fieldTypes) {
				initialValues[field.name] =
					initialData[field.name] ?? field.defaultValue;
			}
		}

		return html`
      <div class="flex flex-col gap-4">
        ${fieldTypes.map((field) => {
					return html`${FieldRenderer.renderField(field, initialValues[field.name], mode)}`;
				})}
      </div>
    `;
	}
}
