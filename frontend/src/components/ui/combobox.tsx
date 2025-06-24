import * as React from "react"
import { Check, ChevronsUpDown, Loader2 } from "lucide-react"

import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
} from "@/components/ui/command"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"

export interface ComboboxOption {
  label: string
  value: string
  description?: string
}

interface ComboboxProps {
  options: ComboboxOption[]
  value?: string
  onValueChange: (value: string) => void
  placeholder?: string
  emptyMessage?: string
  disabled?: boolean
  loading?: boolean
  className?: string
  onSearch?: (value: string) => void
  searchDebounce?: number
}

export function Combobox({
  options,
  value,
  onValueChange,
  placeholder = "Chọn một mục...",
  emptyMessage = "Không tìm thấy kết quả.",
  disabled = false,
  loading = false,
  className,
  onSearch,
  searchDebounce = 300,
}: ComboboxProps) {
  const [open, setOpen] = React.useState(false)
  const [searchValue, setSearchValue] = React.useState("")
  const debouncedSearchRef = React.useRef<NodeJS.Timeout>()

  // Handle search with debounce
  const handleSearch = React.useCallback(
    (value: string) => {
      setSearchValue(value)
      
      if (onSearch) {
        if (debouncedSearchRef.current) {
          clearTimeout(debouncedSearchRef.current)
        }
        
        debouncedSearchRef.current = setTimeout(() => {
          onSearch(value)
        }, searchDebounce)
      }
    },
    [onSearch, searchDebounce]
  )

  // Clear timeout on unmount
  React.useEffect(() => {
    return () => {
      if (debouncedSearchRef.current) {
        clearTimeout(debouncedSearchRef.current)
      }
    }
  }, [])

  const selectedOption = options.find(option => option.value === value)

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className={cn("w-full justify-between", className)}
          disabled={disabled}
        >
          {value && selectedOption
            ? selectedOption.label
            : placeholder}
          {loading ? (
            <Loader2 className="ml-2 h-4 w-4 shrink-0 opacity-50 animate-spin" />
          ) : (
            <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[var(--radix-popover-trigger-width)] p-0">
        <Command shouldFilter={false}>
          <CommandInput 
            placeholder="Tìm kiếm..." 
            value={searchValue}
            onValueChange={handleSearch}
          />
          {loading ? (
            <div className="py-6 text-center">
              <Loader2 className="h-6 w-6 animate-spin mx-auto" />
              <p className="text-sm text-muted-foreground pt-2">
                Đang tìm kiếm...
              </p>
            </div>
          ) : (
            <>
              <CommandEmpty>{emptyMessage}</CommandEmpty>
              <CommandGroup className="max-h-[300px] overflow-auto">
                {options.map((option) => (
                  <CommandItem
                    key={option.value}
                    value={option.value}
                    onSelect={() => {
                      onValueChange(option.value)
                      setOpen(false)
                      setSearchValue("")
                    }}
                    className="flex items-center justify-between"
                  >
                    <div>
                      <span>{option.label}</span>
                      {option.description && (
                        <p className="text-xs text-muted-foreground">
                          {option.description}
                        </p>
                      )}
                    </div>
                    {value === option.value && (
                      <Check className="h-4 w-4 text-primary" />
                    )}
                  </CommandItem>
                ))}
              </CommandGroup>
            </>
          )}
        </Command>
      </PopoverContent>
    </Popover>
  )
} 