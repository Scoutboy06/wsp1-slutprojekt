interface BaseFieldProps {
  type: string,
  name: string,
  mode: string,
  required: boolean,
}

interface StringFieldProps extends BaseFieldProps {
  defaultValue?: string;
}
interface BooleanFieldProps extends BaseFieldProps {
  defaultValue?: boolean;
}

interface UploadInitialValue {
  id: number;
  file_name: string,
  file_path: string,
  height: number | null;
  width: number | null;
  mime_type: string;
  url: string;
}