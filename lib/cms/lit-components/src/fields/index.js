import { LitElement, html } from "lit";
import BooleanField from "./boolean_field";
import EmailField from "./email_field";

export default class Field extends LitElement {
	static properties = {
		type: {},
		name: {},
		defaultValue: {},
		required: {},
		mode: {},
		fields: { default: null },
	};

	render() {
		switch (this.type) {
			case "boolean":
				return html`<boolean-field .name=${this.name} .defaultChecked=${this.defaultValue}></boolean-field>`;
			case "email":
				return html`<email-field .name=${this.name} .defaultValue=${this.defaultValue}></email-field>`;
			default:
				return null;
		}
	}
}
