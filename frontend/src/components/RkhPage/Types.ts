export interface Option {
  label: string;
  value: number;
}

export interface ProjectOption extends Option {
  customer_id: number;
}