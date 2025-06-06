import { LitElement, html } from "lit";

export default class BooleanField extends LitElement {
	static properties = {
		name: {},
		value: {},
		defaultValue: { default: false },
		required: {},
		mode: {},
	};

	createRenderRoot() {
		return this;
	}

	render() {
		return html`
      <div class="flex items-center gap-2">
        <input
          type="checkbox"
          name=${this.name}
          id=${this.name}
          class="border border-black"
          ?checked=${this.value ?? this.defaultValue}
        >
        <label for=${this.name}>${this.name}</label>
      </div>
    `;
	}
}
