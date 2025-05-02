import { LitElement, html } from "lit";

export default class PasswordField extends LitElement {
	static properties = {
		name: {},
		defaultValue: { default: "" },
		required: { default: false },
		mode: {},
	};

	render() {
		return html`
      <div class="flex flex-col gap-2">
        <label for=${this.name}>
          ${this.name}
          ${
						this.required && this.mode !== "edit"
							? html`<span class="text-red-600">*</span>`
							: ""
					}
        </label>
        <input
          type="password"
          name=${this.name}
          id=${this.name}
          class="px-2 py-1 border border-gray-400"
          ?required=${this.required && this.mode !== "edit"}
          placeholder=${this.mode === "edit" ? "Update password" : ""}
        >
      </div>
    `;
	}
}
