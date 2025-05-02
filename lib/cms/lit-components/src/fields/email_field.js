import { LitElement, html } from "lit";

export default class EmailField extends LitElement {
	static properties = {
		name: {},
		defaultValue: { default: "" },
		required: {},
		mode: {},
	};

	createRenderRoot() {
		return this;
	}

	render() {
		return html`
      <div class="flex flex-col gap-2">
        <label for=${this.name}>
          ${this.name ?? "email"}
          ${this.required ? html`<span class="text-red-600">*</span>` : null}
        </label>
        <input
        type="email"
        name=${this.name}
        id=${this.name}
        class="px-2 py-1 border border-gray-400 rounded"
        ?required=${this.required && this.mode !== "edit"}
        value=${this.defaultValue}
      >
      </div>
    `;
	}
}
