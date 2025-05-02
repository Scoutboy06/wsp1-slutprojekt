import { LitElement, html } from "lit";

export default class UploadField extends LitElement {
	static properties = {
		name: {},
		defaultValue: {},
		isDeleted: { state: true },
		fileMeta: { state: true },
		required: {},
		mode: {},
	};

	constructor() {
		super();
		this.isDeleted = false;
	}

	createRenderRoot() {
		return this;
	}

	willUpdate(changedProps) {
		if (changedProps.has("defaultValue")) {
			this.fileMeta = this.defaultValue
				? {
						name: this.defaultValue.file_name,
						dimensions: `${this.defaultValue.width} x ${this.defaultValue.height}`,
						preview: this.defaultValue.url,
					}
				: null;
		}
	}

	handleFileUpload(e) {
		const file = e.target.files[0];
		if (!file || !file.type.startsWith("image/")) return;

		const reader = new FileReader();

		reader.onload = (e) => {
			const img = new Image();
			img.src = e.target.result;

			img.onload = () => {
				if (this.defaultValue) {
					this.isDeleted = true;
				}

				this.fileMeta = {
					name: file.name,
					size: (file.size / 1024).toFixed(2) + " KB",
					dimensions: `${img.width} x ${img.height}`,
					preview: e.target.result,
				};
			};
		};

		reader.readAsDataURL(file);
	}

	removeFile() {
		const inputElement = this.querySelector(`input[type=file]#${this.name}`);
		inputElement.value = "";

		this.fileMeta = null;
		if (this.defaultValue) {
			this.isDeleted = true;
		}
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
          	ref=${this.inputRef}
            type="file"
            name=${this.name}
            id=${this.name}
            accept="image/*"
            @change=${this.handleFileUpload}
          >
          <input
            type="checkbox"
            name="${this.name}__deleted"
            id="${this.name}__deleted"
            class="hidden"
          >
          ${
						this.fileMeta
							? html`
            <div class="relative p-2 mt-2 border border-gray-400 rounded">
              <img src=${this.fileMeta.preview} class="w-auto h-20">
              <p>${this.fileMeta?.name}</p>
              <p>${this.fileMeta?.size}</p>
              <p>${this.fileMeta?.dimensions}</p>
              <button type="button" @click=${this.removeFile} class="icon">delete</button>
            </div>
          `
							: null
					}
        </div>
      </div>
    `;
	}
}
