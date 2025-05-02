import { LitElement, html } from "lit";

export default class StringField extends LitElement {
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
          ${this.name ?? ""}
          ${this.required ? html`<span class="text-red-600">*</span>` : ""}
        </label>
        <input
          type="text"
          ?disabled=${this.mode === "relation"}
          name=${this.name}
          id=${this.name}
          class="px-2 py-1 border border-gray-400 rounded${this.mode === "relation" ? " bg-gray-100" : ""}"
          value=${this.defaultValue}
          ?required=${this.required}
        >
      </div>
    `;
	}
}
