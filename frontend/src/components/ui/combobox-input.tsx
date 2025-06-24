import * as React from "react"
import { Check, Loader2 } from "lucide-react"
import { cn } from "@/lib/utils"

export interface ComboboxOption {
  label: string
  value: string
  description?: string
}

interface ComboboxInputProps {
  options: ComboboxOption[]
  value?: string
  onValueChange: (value: string) => void
  onInputChange: (value: string) => void
  inputValue: string
  placeholder?: string
  emptyMessage?: string
  disabled?: boolean
  loading?: boolean
  className?: string
  id?: string
  name?: string
  autoComplete?: string
}

export function ComboboxInput({
  options,
  value,
  onValueChange,
  onInputChange,
  inputValue,
  placeholder = "Tìm kiếm...",
  emptyMessage = "Không tìm thấy kết quả.",
  disabled = false,
  loading = false,
  className,
  id,
  name,
  autoComplete = "off",
}: ComboboxInputProps) {
  const [showSuggestions, setShowSuggestions] = React.useState(false)
  const wrapperRef = React.useRef<HTMLDivElement>(null)
  const inputRef = React.useRef<HTMLInputElement>(null)

  // Handle input change
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    onInputChange(value)
    setShowSuggestions(true)
  }

  // Handle option selection
  const handleSelect = (selectedValue: string, selectedLabel: string) => {
    onValueChange(selectedValue)
    onInputChange(selectedLabel)
    setShowSuggestions(false)
    
    // Return focus to input after selection
    if (inputRef.current) {
      inputRef.current.focus()
    }
  }

  // Handle input focus
  const handleFocus = () => {
    if (options.length > 0) {
      setShowSuggestions(true)
    }
  }

  // Close dropdown when clicking outside
  React.useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
        setShowSuggestions(false)
      }
    }

    document.addEventListener("mousedown", handleClickOutside)
    return () => {
      document.removeEventListener("mousedown", handleClickOutside)
    }
  }, [])

  return (
    <div className="w-full relative" ref={wrapperRef}>
      <input
        ref={inputRef}
        type="text"
        className={cn(
          "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm",
          "placeholder:text-muted-foreground",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background",
          "disabled:cursor-not-allowed disabled:opacity-50",
          className
        )}
        placeholder={placeholder}
        value={inputValue}
        onChange={handleInputChange}
        onFocus={handleFocus}
        onClick={() => {
          if (options.length > 0 && !showSuggestions) {
            setShowSuggestions(true)
          }
        }}
        disabled={disabled}
        id={id}
        name={name}
        autoComplete={autoComplete}
        aria-expanded={showSuggestions}
      />

      {loading && (
        <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
          <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
        </div>
      )}

      {showSuggestions && options.length > 0 && (
        <ul 
          className="absolute z-50 mt-1 max-h-60 w-full overflow-auto rounded-md border border-input bg-background py-1 shadow-md"
          role="listbox"
        >
          {options.map((option) => (
            <li
              key={option.value}
              className={cn(
                "relative cursor-pointer select-none py-1.5 px-3 text-sm",
                "hover:bg-accent hover:text-accent-foreground",
                value === option.value ? "bg-accent text-accent-foreground" : "text-foreground"
              )}
              onClick={() => handleSelect(option.value, option.label)}
              role="option"
              aria-selected={value === option.value}
            >
              <div className="flex justify-between items-center">
                <div>
                  <span>{option.label}</span>
                  {option.description && (
                    <p className="text-xs text-muted-foreground">{option.description}</p>
                  )}
                </div>
                {value === option.value && <Check className="h-4 w-4" />}
              </div>
            </li>
          ))}
        </ul>
      )}

      {showSuggestions && options.length === 0 && !loading && (
        <div className="absolute z-50 mt-1 w-full rounded-md border border-input bg-background py-2 px-3 shadow-md">
          <p className="text-sm text-muted-foreground">{emptyMessage}</p>
        </div>
      )}
    </div>
  )
} 