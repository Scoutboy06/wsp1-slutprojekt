import { LitElement, html } from "lit";

export default class UploadField extends LitElement {
	/** @type {UploadInitialValue | null} */
	defaultValue;
	/** @type {UploadInitialValue | null} */
	value;

	static properties = {
		name: {},
		defaultValue: {},
		required: {},
		mode: {},
	};

	// constructor() {
	// 	super();
	// 	this.value = this.defaultValue;
	// }

	createRenderRoot() {
		return this;
	}

	render() {
		return html`
      <div class="flex flex-col gap-2">
        <label for=${this.name}>
          ${this.name}
          ${this.required ? html`<span class="text-red-600">*</span>` : null}
        </label>
        <div class="px-4 py-4 border border-gray-400 rounded">
          <input
            type="file"
            name=${this.name}
            id=${this.name}
            accept="image/*"
            onchange="console.log"
          >
          <input
            type="checkbox"
            name="${this.name}__deleted"
            id="${this.name}__deleted"
            class="hidden"
          >
          ${
						this.value
							? html`
            <div class="relative p-2 mt-2 border border-gray-400 rounded">
              <img src="" class="w-auto h-20">
              <p></p>
              <p></p>
              <p></p>
              <button type="button" onclick="console.log" class="icon">delete</button>
            </div>
          `
							: null
					}
        </div>
      </div>
    `;
	}
}

customElements.define("upload-field", UploadField);
