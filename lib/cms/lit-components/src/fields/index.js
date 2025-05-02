import { LitElement, html } from "lit";
import StringField from "./string_field";
import BooleanField from "./boolean_field";
import EmailField from "./email_field";
import PasswordField from "./password_field";
import UploadField from "./upload_field";

class FieldRenderer extends LitElement {
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
	 * @param {'create' | 'edit'} mode
	 */
	renderField(field, mode) {
		console.log(field);
		switch (field.type) {
			case "string":
				return html`<string-field .name=${field.name} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></string-field>`;
			case "boolean":
				return html`<boolean-field .name=${field.name} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></boolean-field>`;
			case "email":
				return html`<email-field .name=${field.name} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></email-field>`;
			case "password":
				return html`<password-field .name=${field.name} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></password-field>`;
			case "upload":
				return html`<upload-field .name=${field.name} .defaultValue=${field.default} .required=${field.required} .mode=${mode}></upload-field>`;
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

		const fields = fieldTypes.map((field) => {
			const _default = mode === "edit"
						? (initialData[field.name] ?? field.defaultValue)
						: field.defaultValue;
			
			return {
				...field,
				default: _default,
			};
		});

		return html`
      <div class="flex flex-col gap-4">
        ${fields.map((field) => {
					return html`${this.renderField(field, mode)}`;
				})}
      </div>
    `;
	}
}

customElements.define("field-renderer", FieldRenderer);
