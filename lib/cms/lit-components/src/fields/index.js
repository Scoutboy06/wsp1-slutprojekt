import StringField from "./string_field";
import BooleanField from "./boolean_field";
import EmailField from "./email_field";
import PasswordField from "./password_field";
import UploadField from "./upload_field";
import ArrayField from "./array_field.js";
import FieldRenderer from "./field_renderer.js";
import RelationField from "./relation_field.js";

customElements.define("string-field", StringField);
customElements.define("boolean-field", BooleanField);
customElements.define("email-field", EmailField);
customElements.define("password-field", PasswordField);
customElements.define("upload-field", UploadField);
customElements.define("array-field", ArrayField);
customElements.define("field-renderer", FieldRenderer);
customElements.define("relation-field", RelationField);
