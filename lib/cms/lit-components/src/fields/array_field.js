import { LitElement, html } from 'lit';

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
    if(changedProps.has('defaultValue')) {
      this.items = this.defaultValue;
    }
  }

  render() {
    return html`
      <div class="flex flex-col gap-2">
        <p>${this.name}</p>
        <div class="px-4 py-4 border border-gray-400 rounded">
          ${this.items.map(item => html`
            <div class="px-4 py-2 border border-gray-400 rounded">
              ${this.fields.map(field => html`
                <p>${field.name}</p>
                <div class="px-4 py-2 border border-gray-400 rounded">
                </div>
              `)}
            </div>
          `)}
        </div>
      </div>
    `;
  }
}

customElements.define('array-field', ArrayField);
